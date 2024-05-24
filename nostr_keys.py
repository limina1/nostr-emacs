from pynostr.key import PrivateKey
from pynostr.event import Event
from pynostr.relay_manager import RelayManager
from pynostr.filters import FiltersList, Filters
from pynostr.message_type import ClientMessageType
import uuid
import ssl
import json
import time
import sys

nsec = "nsec1swfhcrsvmfw5actkgw5445k48lewpund60ff90mm5j3up0wat8pqfqced2"
nhex = "83937c0e0cda5d4ee17643a95ad2d53ff2e0f26dd3d292bf7ba4a3c0bddd59c2"
raw_secret = b"\xb7\xe9\xba\xa3\xa6\x11\xdb=\x9cZLY\x1f\x0c\xa8=\x96l-\xb2u\xd8\xcf\x8c\xe9c\xf6\x02N6;s"
private_key = PrivateKey.from_nsec(nsec)
npub = private_key.public_key.bech32()

print("testing")
if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "sign":
            print("Signing")
            message = sys.argv[2]
            # signature = private_key.sign(bytes.fromhex(message))
            relay_manager = RelayManager(timeout=6)
            relay_manager.add_relay("wss://relay.damus.io/")
            relay_manager.add_relay("wss://relay.nostr.band/")
            filters = FiltersList(
                [Filters(authors=[private_key.public_key.hex()], limit=100)]
            )
            subscription_id = uuid.uuid1().hex
            relay_manager.add_subscription_on_all_relays(subscription_id, filters)
            event = Event(message)
            event.sign(private_key.hex())
            print("Publishing Event")
            relay_manager.publish_event(event)
            print("Running Sync")
            relay_manager.run_sync()
            time.sleep(5)
            while relay_manager.message_pool.has_ok_notices():
                ok_msg = relay_manager.message_pool.get_ok_notice()
                print(ok_msg)
            while relay_manager.message_pool.has_events():
                event_msg = relay_manager.message_pool.get_event()
                print(event_msg.event.to_dict())
        elif sys.argv[1] == "load_key":
            print("Loading Key")
            filename = sys.argv[2]
