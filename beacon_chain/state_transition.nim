# beacon_chain
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.


# Note: this is also inspired by https://github.com/ethereum/beacon_chain/blob/master/beacon_chain/state/state_transition.py
# The official spec at https://notes.ethereum.org/SCIg8AH5SA-O4C1G1LYZHQ# is not fully
# defining the state transitions.
#
# Note that the ethresearch impl is using "block_vote_cache" field, which is a dictionary mapping hashes
# to the following sub-dictionary:
#     {
#       'voter_indices': set(),
#       'total_voter_deposits': 0
#     }
# It should not be needed anymore with the new AttestationRecord type

{.warning: "The official spec at https://notes.ethereum.org/SCIg8AH5SA-O4C1G1LYZHQ# is not fully defining state transitions.".}

import ./datatypes, ./private/helpers, intsets


func process_block(active_state: ActiveState, crystallized_state: CrystallizedState, blck: BeaconBlock, slot: int64) =
  # TODO: unfinished spec

  for attestation in blck.attestations:
    # Verify that slot < block.slot_number and slot >= max(block.slot_number - CYCLE_LENGTH, 0)
    doAssert slot < blck.slot_number
    doAssert slot >= max(blck.slot_number - CYCLE_LENGTH, 0)

    # Compute parent_hashes = [get_block_hash(active_state, block, slot - CYCLE_LENGTH + i) for i in range(CYCLE_LENGTH - len(oblique_parent_hashes))] + oblique_parent_hashes
    # TODO - don't allocate in tight loop
    var parent_hashes = newSeq[Blake2_256_Digest](CYCLE_LENGTH - attestation.oblique_parent_hashes.len)
    for idx, val in parent_hashes.mpairs:
      val = get_block_hash(active_state, blck, slot - CYCLE_LENGTH + idx)
    parent_hashes.add attestation.oblique_parent_hashes

    # Let attestation_indices be get_shards_and_committees_for_slot(crystallized_state, slot)[x], choosing x so that attestation_indices.shard_id equals the shard_id value provided to find the set of validators that is creating this attestation record.
    let attestation_indices = block:
      let shard_and_committees = get_shards_and_committees_for_slot(crystallized_state, slot)
      var
        x = 1
        record_creator = shard_and_committees[0]
      while record_creator.shard_id != attestation.shard_id:
        record_creator = shard_and_committees[x]
        inc x
      record_creator

    # Verify that len(attester_bitfield) == ceil_div8(len(attestation_indices)), where ceil_div8 = (x + 7) // 8. Verify that bits len(attestation_indices).... and higher, if present (i.e. len(attestation_indices) is not a multiple of 8), are all zero
    doAssert attestation.attester_bitfield.len == attestation_indices.committee.len

    # Derive a group public key by adding the public keys of all of the attesters in attestation_indices for whom the corresponding bit in attester_bitfield (the ith bit is (attester_bitfield[i // 8] >> (7 - (i %8))) % 2) equals 1
    # TODO

    # Verify that aggregate_sig verifies using the group pubkey generated and hash((slot % CYCLE_LENGTH).to_bytes(8, 'big') + parent_hashes + shard_id + shard_block_hash) as the message.
    # TODO

  # Extend the list of AttestationRecord objects in the active_state, ordering the new additions in the same order as they came in the block.
  # TODO

  # Verify that the slot % len(get_indices_for_slot(crystallized_state, slot-1)[0])'th attester in get_indices_for_slot(crystallized_state, slot-1)[0]is part of at least one of the AttestationRecord objects; this attester can be considered to be the proposer of the block.
  # TODO
