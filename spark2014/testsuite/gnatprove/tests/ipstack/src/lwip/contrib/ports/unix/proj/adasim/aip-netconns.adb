------------------------------------------------------------------------------
--                            IPSTACK COMPONENTS                            --
--             Copyright (C) 2010, Free Software Foundation, Inc.           --
------------------------------------------------------------------------------

with AIP.Config;

package body AIP.Netconns is

   function Netconn_New (Ctype : Netconn_Kind) return Netconn_Id is
   begin
      return Netconn_New_PC (Ctype => Ctype, Proto => 0, Cb => 0);
   end Netconn_New;

   procedure Netconn_Listen (NC : Netconn_Id) is
   begin
      Netconn_Listen_BL (NC, Config.TCP_DEFAULT_LISTEN_BACKLOG);
   end Netconn_Listen;

end AIP.Netconns;
