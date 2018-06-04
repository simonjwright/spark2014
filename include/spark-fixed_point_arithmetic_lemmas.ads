------------------------------------------------------------------------------
--                                                                          --
--                        SPARK LIBRARY COMPONENTS                          --
--                                                                          --
--                                S P A R K .                               --
--        F I X E D _ P O I N T _ A R I T H M E T I C _ L E M M A S         --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                       Copyright (C) 2018, AdaCore                        --
--                                                                          --
-- SPARK is free software;  you can  redistribute it and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. SPARK is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

generic
   type Fix is delta <>;
package SPARK.Fixed_Point_Arithmetic_Lemmas
  with Pure,
       Ghost
is
   pragma Warnings
     (Off, "postcondition does not check the outcome of calling");

   procedure GNAT_Lemma_Div_Is_Monotonic
     (Num1  : Fix;
      Num2  : Fix;
      Denom : Positive)
   with
     Global => null,
     Pre  => Num1 <= Num2,
     Post => Num1 / Denom <= Num2 / Denom;
   pragma Annotate (GNATprove, Intentional, "postcondition",
                    "GNAT-specific lemma, as Ada RM does not guarantee it");
   --  GNAT implements division of fixed-point type by Integer with integer
   --  division, which is monotonic in its numerator.

   procedure GNAT_Lemma_Div_Is_Antimonotonic
     (Num    : Fix;
      Denom1 : Positive;
      Denom2 : Positive)
   with
     Global => null,
     Pre  => Num >= 0.0
       and then Denom1 <= Denom2,
     Post => Num / Denom1 >= Num / Denom2;
   pragma Annotate (GNATprove, Intentional, "postcondition",
                    "GNAT-specific lemma, as Ada RM does not guarantee it");
   --  GNAT implements division of fixed-point type by Integer with integer
   --  division, which is antimonotonic in its denominator, when all arguments
   --  are non-negative.

   procedure GNAT_Lemma_Mult_Then_Div_Is_Ident
     (Val1 : Fix;
      Val2 : Positive)
   with
     Global => null,
     Pre  => Val1 in 0.0 .. Fix'Last / Val2,
     Post => (Val1 * Val2) / Val2 = Val1;
   pragma Annotate (GNATprove, Intentional, "overflow check",
                    "GNAT-specific lemma, as Ada RM does not guarantee it");
   --  GNAT implements division of fixed-point type by Integer with integer
   --  division, which ensures that Fix'Last / Val2 is rounded to zero. Hence
   --  the multiplication (Val1 * Val2) in the postcondition cannot overflow.

end SPARK.Fixed_Point_Arithmetic_Lemmas;
