------------------------------------------------------------------------------
--                                                                          --
--                  Copyright (C) 2015-2016, AdaCore                        --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of STMicroelectronics nor the names of its       --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

with STM32.Device;  use STM32.Device;
with HAL;           use HAL;

package body Serial_IO.Blocking is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (This : out Serial_Port) is
      Configuration : GPIO_Port_Configuration;
   begin
      Enable_Clock (This.Device.Rx_Pin & This.Device.Tx_Pin);
      Enable_Clock (This.Device.Transceiver.all);

      Configuration.Mode        := Mode_AF;
      Configuration.Speed       := Speed_50MHz;
      Configuration.Output_Type := Push_Pull;
      Configuration.Resistors   := Pull_Up;

      Configure_IO
        (This.Device.Rx_Pin & This.Device.Tx_Pin,
         Configuration);

      Configure_Alternate_Function
        (This.Device.Rx_Pin & This.Device.Tx_Pin,
         This.Device.Transceiver_AF);
      This.Initialized := True;
   end Initialize;

   -----------------
   -- Initialized --
   -----------------

   function Initialized (This : Serial_Port) return Boolean is (This.Initialized);

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (This      : in out Serial_Port;
      Baud_Rate : Baud_Rates;
      Parity    : Parities     := No_Parity;
      Data_Bits : Word_Lengths := Word_Length_8;
      End_Bits  : Stop_Bits    := Stopbits_1;
      Control   : Flow_Control := No_Flow_Control)
   is
   begin
      Disable (This.Device.Transceiver.all);

      Set_Baud_Rate    (This.Device.Transceiver.all, Baud_Rate);
      Set_Mode         (This.Device.Transceiver.all, Tx_Rx_Mode);  -- hardcoded ??
      Set_Stop_Bits    (This.Device.Transceiver.all, End_Bits);
      Set_Word_Length  (This.Device.Transceiver.all, Data_Bits);
      Set_Parity       (This.Device.Transceiver.all, Parity);
      Set_Flow_Control (This.Device.Transceiver.all, Control);

      Enable (This.Device.Transceiver.all);
   end Configure;

   ---------
   -- Put --
   ---------

   procedure Put (This : in out Serial_Port;  Value : Character) is
   begin
      Await_Send_Ready (This.Device.Transceiver.all);
      Transmit (This.Device.Transceiver.all, Character'Pos (Value));
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (This : in out Serial_Port;  Value : String) is
   begin
      for Next_Char of Value loop
         Await_Send_Ready (This.Device.Transceiver.all);
         Transmit (This.Device.Transceiver.all, Character'Pos (Next_Char));
      end loop;
   end Put;

   ---------
   -- Get --
   ---------

   procedure Get (This : in out Serial_Port;  Value : out Character) is
      Raw : UInt9;
   begin
      Await_Data_Available (This.Device.Transceiver.all);
      Receive (This.Device.Transceiver.all, Raw);
      Value := Character'Val (Raw);
   end Get;

   ---------
   -- Get --
   ---------

   procedure Get
     (This       : in out Serial_Port;
      Value      : out String;
      Last       : out Natural;
      Terminator : Character)
   is
      Raw           : UInt9;
      Received_Char : Character;
   begin
      Receiving : for Index in Value'Range loop
         Await_Data_Available (This.Device.Transceiver.all);
         Receive (This.Device.Transceiver.all, Raw);
         Received_Char := Character'Val (Raw);
         exit Receiving when Received_Char = Terminator;
         Value (Index) := Received_Char;
         Last := Index;
      end loop Receiving;
   end Get;

   ---------
   -- Put --
   ---------

   procedure Put (This : in out Serial_Port;  Msg : not null access Message) is
   begin
      Put (This, Content (Msg.all));
   end Put;

   ---------
   -- Get --
   ---------

   procedure Get (This : in out Serial_Port;  Msg : not null access Message) is
   begin
      Get (This, Msg.Content, Msg.Length, Msg.Terminator);
   end Get;

   ----------------------
   -- Await_Send_Ready --
   ----------------------

   procedure Await_Send_Ready (This : USART) is
   begin
      loop
         exit when Tx_Ready (This);
      end loop;
   end Await_Send_Ready;

   --------------------------
   -- Await_Data_Available --
   --------------------------

   procedure Await_Data_Available (This : USART) is
   begin
      loop
         exit when Rx_Ready (This);
      end loop;
   end Await_Data_Available;

end Serial_IO.Blocking;
