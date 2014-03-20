
module Ieee154AddressP 
{
    provides 
    {
        interface Ieee154Address;
        interface Init;
    }

} 
implementation 
{
  ieee154_saddr_t m_saddr;
  ieee154_panid_t m_panid;

    command error_t Init.init() 
    {
        m_saddr = TOS_NODE_ID;
        m_panid = TOS_AM_GROUP;
        return SUCCESS;
    }

    command ieee154_panid_t Ieee154Address.getPanId() {
        return m_panid;
    }
    command ieee154_saddr_t Ieee154Address.getShortAddr() {
        return m_saddr;
    }
    
  command ieee154_laddr_t Ieee154Address.getExtAddr() {
    ieee154_laddr_t addr;
    int i;

    for (i = 0; i < 8; i++) {

      addr.data[i] = 0x00;
    }
    addr.data[7] = 0x03;
    return addr;
  }

  command error_t Ieee154Address.setShortAddr(ieee154_saddr_t addr) {
    bl_printf("Changed addr from %d to %d\n", m_saddr, addr);
    m_saddr = addr;
    signal Ieee154Address.changed();
    return SUCCESS;
  }

}
