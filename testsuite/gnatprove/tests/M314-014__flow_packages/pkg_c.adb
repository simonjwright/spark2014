package body Pkg_C
  with Refined_State => (State_A => X,
                         State_B => Y,
                         State_C => Z)
is
   X : Integer := 0;
   Y : Integer;
   Z : Integer;

   procedure Do_Stuff (P : in     Integer;
                       Q : in out Integer;
                       R :    out Integer)
   with Global  => null,
        Depends => (Q =>+ null,
                    R => null,
                    null => P)
   is
   begin
      R := 0;
   end Do_Stuff;

begin
   Y := Other.X;    --  use of uninitialized state
                    --  also violdates contract as other.state_d is not used

   Z := 55;         --  State_C is not initialized

   Other.X := 12;   --  can only initialize my own state
end Pkg_C;
