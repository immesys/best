module RF230BarePacketP
{
    provides interface Packet as BarePacket;
    uses interface RadioPacket;
}
implementation
{
  command void BarePacket.clear(message_t *msg)
  {
    call RadioPacket.clear(msg);
  }

  command uint8_t BarePacket.payloadLength(message_t *msg)
  {
    return call RadioPacket.payloadLength(msg);
  }

  command void BarePacket.setPayloadLength(message_t *msg, uint8_t len)
  {
    call RadioPacket.setPayloadLength(msg, len);
  }

  command uint8_t BarePacket.maxPayloadLength()
  {
    return call RadioPacket.maxPayloadLength();
  }

  command void *BarePacket.getPayload(message_t *msg, uint8_t len)
  {
    if (len > call RadioPacket.maxPayloadLength())
      return NULL;
    else
      return (void*)msg;
  }
}


