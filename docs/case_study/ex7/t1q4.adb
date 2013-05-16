package body T1Q4
is

   procedure ISQRT(N: in Natural; Root: out Natural)
   is
      -- Introduce a new subtype to use to avoid possible overflow
      -- of expression in loop exit statement.
      subtype Big_Natural is long_long_integer range 0..Long_Long_Integer'Last;

      Local_Root : Big_Natural;

   begin
      Local_Root := 0;

      loop
         exit when (Local_Root + 1) * (Local_Root + 1) > Big_Natural (N);

         Local_Root := Local_Root + 1;

       -- Loop Invariant is in terms of the incremented value of Local_Root.
       pragma Loop_Invariant
         (Local_Root * Local_Root <= Big_Natural(N)
          and then Local_Root <= Big_Natural(Natural'Last));
       --# assert Local_Root * Local_Root <= Big_Natural(N) and
       --#        Local_Root <= Big_Natural(N);

      end loop;

      Root := Natural(Local_Root);
   end ISQRT;
end T1Q4;
