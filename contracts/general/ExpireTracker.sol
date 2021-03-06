// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

import '../libraries/SafeMath.sol';
/**
 * @title Expire Traker
 * @dev Keeps track of expired NFTs.
**/
contract ExpireTracker {
    
    using SafeMath for uint64;
    using SafeMath for uint256;

    // 1 day for each step.
    uint64 public constant BUCKET_STEP = 1 days;

    // indicates where to start from 
    // points where TokenInfo with (expiredAt / BUCKET_STEP) == index
    mapping(uint64 => Bucket) public checkPoints;

    struct Bucket {
        uint96 head;
        uint96 tail;
    }

    // points first active nft
    uint96 public head;
    // points last active nft
    uint96 public tail;

    // maps expireId to deposit info
    mapping(uint96 => ExpireMetadata) public infos; 
    
    // pack data to reduce gas
    struct ExpireMetadata {
        uint96 next; // zero if there is no further information
        uint96 prev;
        uint64 expiresAt;
    }

    function expired() internal view returns(bool) {
        if(infos[head].expiresAt == 0) {
            return false;
        }

        if(infos[head].expiresAt <= uint64(now)){
            return true;
        }

        return false;
    }

    // using typecasted expireId to save gas
    function push(uint96 expireId, uint64 expiresAt) 
      internal 
    {
        require(expireId != 0, "info id 0 cannot be supported");

        // If this is a replacement for a current balance, remove it's current link first.
        if (infos[expireId].expiresAt > 0) pop(expireId);

        uint64 bucket = uint64( (expiresAt.div(BUCKET_STEP)).mul(BUCKET_STEP) );
        if (head == 0) {
            // all the nfts are expired. so just add
            head = expireId;
            tail = expireId; 
            checkPoints[bucket] = Bucket(expireId, expireId);
            infos[expireId] = ExpireMetadata(0,0,expiresAt);
            
            return;
        }
            
        // there is active nft. we need to find where to push
        // first check if this expires faster than head
        if (infos[head].expiresAt >= expiresAt) {
            // pushing nft is going to expire first
            // update head
            infos[head].prev = expireId;
            infos[expireId] = ExpireMetadata(head,0,expiresAt);
            head = expireId;
            
            // update head of bucket
            Bucket storage b = checkPoints[bucket];
            b.head = expireId;
                
            if(b.tail == 0) {
                // if tail is zero, this bucket was empty should fill tail with expireId
                b.tail = expireId;
            }
                
            // this case can end now
            return;
        }
          
        // then check if depositing nft will last more than latest
        if (infos[tail].expiresAt <= expiresAt) {
            infos[tail].next = expireId;
            // push nft at tail
            infos[expireId] = ExpireMetadata(0,tail,expiresAt);
            tail = expireId;
            
            // update tail of bucket
            Bucket storage b = checkPoints[bucket];
            b.tail = expireId;
            
            if(b.head == 0){
              // if head is zero, this bucket was empty should fill head with expireId
              b.head = expireId;
            }
            
            // this case is done now
            return;
        }
          
        // so our nft is somewhere in between
        if (checkPoints[bucket].head != 0) {
            //bucket is not empty
            //we just need to find our neighbor in the bucket
            uint96 cursor = checkPoints[bucket].head;
        
            // iterate until we find our nft's next
            while(infos[cursor].expiresAt < expiresAt){
                cursor = infos[cursor].next;
            }
        
            infos[expireId] = ExpireMetadata(cursor, infos[cursor].prev, expiresAt);
            infos[infos[cursor].prev].next = expireId;
            infos[cursor].prev = expireId;
        
            //now update bucket's head/tail data
            Bucket storage b = checkPoints[bucket];
            
            if (infos[b.head].prev == expireId){
                b.head = expireId;
            }
            
            if (infos[b.tail].next == expireId){
                b.tail = expireId;
            }
        } else {
            //bucket is empty
            //should find which bucket has depositing nft's closest neighbor
            // step 1 find prev bucket
            uint64 prevCursor = bucket - BUCKET_STEP;
            
            while(checkPoints[prevCursor].tail == 0){
              prevCursor = uint64( prevCursor.sub(BUCKET_STEP) );
            }
    
            uint96 prev = checkPoints[prevCursor].tail;
            uint96 next = infos[prev].next;
    
            // step 2 link prev buckets tail - nft - next buckets head
            infos[expireId] = ExpireMetadata(next,prev,expiresAt);
            infos[prev].next = expireId;
            infos[next].prev = expireId;
    
            checkPoints[bucket].head = expireId;
            checkPoints[bucket].tail = expireId;
        }
    }

    function _pop(uint96 expireId, uint256 bucketStep) private {
        uint64 expiresAt = infos[expireId].expiresAt;
        uint64 bucket = uint64( (expiresAt.div(bucketStep)).mul(bucketStep) );
        // check if bucket is empty
        // if bucket is empty, end
        if(checkPoints[bucket].head == 0){
            return;
        }
        // if bucket is not empty, iterate through
        // if expiresAt of current cursor is larger than expiresAt of parameter, reverts
        for(uint96 cursor = checkPoints[bucket].head; infos[cursor].expiresAt <= expiresAt; cursor = infos[cursor].next) {
            ExpireMetadata memory info = infos[cursor];
            // if expiresAt is same of paramter, check if expireId is same
            if(info.expiresAt == expiresAt && cursor == expireId) {
                // if yes, delete it
                // if cursor was head, move head to cursor.next
                if(head == cursor) {
                    head = info.next;
                }
                // if cursor was tail, move tail to cursor.prev
                if(tail == cursor) {
                    tail = info.prev;
                }
                // if cursor was head of bucket
                if(checkPoints[bucket].head == cursor){
                    // and cursor.next is still in same bucket, move head to cursor.next
                    if(infos[info.next].expiresAt.div(bucketStep) == bucket.div(bucketStep)) {
                        checkPoints[bucket].head = info.next;
                    } else {
                        // delete whole checkpoint if bucket is now empty
                        delete checkPoints[bucket];
                    }
                } else if(checkPoints[bucket].tail == cursor){
                    // since bucket.tail == bucket.haed == cursor case is handled at the above,
                    // we only have to handle bucket.tail == cursor != bucket.head
                    checkPoints[bucket].tail = info.prev;
                }
                // now we handled all tail/head situation, we have to connect prev and next
                infos[info.prev].next = info.next;
                infos[info.next].prev = info.prev;
                // delete info and end
                delete infos[cursor];
                return;
            }
            // if not, continue -> since there can be same expires at with multiple expireId
        }
        //changed to return for consistency
        return;
        //revert("Info does not exist");
    }

    function pop(uint96 expireId) internal {
        _pop(expireId, BUCKET_STEP);
    }

    function pop(uint96 expireId, uint256 step) internal {
        _pop(expireId, step);
    }

    uint256[50] private __gap;
}
