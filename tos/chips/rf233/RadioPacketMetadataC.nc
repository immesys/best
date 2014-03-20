
/* Wrapper config for interfaces that operate on the metadata level of a packet.
 * This is designed for BLIP, and any radio that wishes to support BLIP needs
 * to create this configuration and provide these interfaces.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration RadioPacketMetadataC {
  provides {
    interface LowPowerListening;
    interface PacketLink;
    interface PacketAcknowledgements;
  }
}

implementation {
  components RF230RadioC;
  
  

  LowPowerListening = RF230RadioC.LowPowerListening;
  PacketLink = RF230RadioC.PacketLink;
  PacketAcknowledgements = RF230RadioC.PacketAcknowledgements;
}
