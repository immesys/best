
module BareAdapterC
{
    uses
    {
        interface BareSend;
     //   interface BareReceive;
        interface Packet;
    }
    provides
    {
        interface Send;
      //  interface Receive;
    }
}
implementation
{
    
  /** 
    * Send a packet with a data payload of <tt>len</tt>. To determine
    * the maximum available size, use the Packet interface of the
    * component providing Send. If send returns SUCCESS, then the
    * component will signal the sendDone event in the future; if send
    * returns an error, it will not signal sendDone.  Note that a
    * component may accept a send request which it later finds it
    * cannot satisfy; in this case, it will signal sendDone with an
    * appropriate error code.
    *
    * @param   'message_t* ONE msg'     the packet to send
    * @param   len     the length of the packet payload
    * @return          SUCCESS if the request was accepted and will issue
    *                  a sendDone event, EBUSY if the component cannot accept
    *                  the request now but will be able to later, FAIL
    *                  if the stack is in a state that cannot accept requests
    *                  (e.g., it's off).
    */ 
  command error_t Send.send(message_t* msg, uint8_t len)
  {
    return call BareSend.send(msg);
  }

  /**
    * Cancel a requested transmission. Returns SUCCESS if the 
    * transmission was cancelled properly (not sent in its
    * entirety). Note that the component may not know
    * if the send was successfully cancelled, if the radio is
    * handling much of the logic; in this case, a component
    * should be conservative and return an appropriate error code.
    *
    * @param   'message_t* ONE msg'    the packet whose transmission should be cancelled
    * @return         SUCCESS if the packet was successfully cancelled, FAIL
    *                 otherwise
    */
  command error_t Send.cancel(message_t* msg)
  {
    return call BareSend.cancel(msg);
  }

  event void BareSend.sendDone(message_t* msg, error_t error)
  {
    signal Send.sendDone(msg, error);
  }

/*  event message_t* BareReceive.receive(message_t* msg)
  {
    return signal BareReceive.receive(msg);
  }*/

   /**
   * Return the maximum payload length that this communication layer
   * can provide. This command behaves identically to
   * <tt>Packet.maxPayloadLength</tt> and is included in this
   * interface as a convenience.
   *
   * @return  the maximum payload length
   */

  
  command uint8_t Send.maxPayloadLength()
  {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg, uint8_t len)
  {
    return call Packet.getPayload(msg, len);
  }
}
