------------------------------------------------------------------------------
--                                                                          --
--                            GNAT2WHY COMPONENTS                           --
--                                                                          --
--                      G N A T 2 W H Y - T Y P E S                         --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                       Copyright (C) 2010-2011, AdaCore                   --
--                                                                          --
-- gnat2why is  free  software;  you can redistribute it and/or modify it   --
-- under terms of the  GNU General Public License as published  by the Free --
-- Software Foundation;  either version  2,  or  (at your option) any later --
-- version. gnat2why is distributed in the hope that it will  be  useful,   --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHAN-  --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details. You  should  have  received a copy of the GNU --
-- General Public License  distributed with GNAT; see file COPYING. If not, --
-- write to the Free Software Foundation,  51 Franklin Street, Fifth Floor, --
-- Boston,                                                                  --
--                                                                          --
-- gnat2why is maintained by AdaCore (http://www.adacore.com)               --
--                                                                          --
------------------------------------------------------------------------------

with Atree;              use Atree;
with Einfo;              use Einfo;
with Gnat2Why.Decls;     use Gnat2Why.Decls;
with Namet;              use Namet;
with Sem_Eval;           use Sem_Eval;
with Sinfo;              use Sinfo;
with Stand;              use Stand;
with String_Utils;       use String_Utils;
with Why;                use Why;
with Why.Conversions;    use Why.Conversions;
with Why.Atree.Builders; use Why.Atree.Builders;
with Why.Gen.Arrays;     use Why.Gen.Arrays;
with Why.Gen.Enums;      use Why.Gen.Enums;
with Why.Gen.Ints;       use Why.Gen.Ints;
with Why.Gen.Names;      use Why.Gen.Names;
with Why.Gen.Records;    use Why.Gen.Records;

with Gnat2Why.Subprograms; use Gnat2Why.Subprograms;

package body Gnat2Why.Types is

   procedure Declare_Ada_Abstract_Signed_Int_From_Range
      (File : W_File_Id;
       Name : String;
       Rng  : Node_Id);
   --  Same as Declare_Ada_Abstract_Signed_Int but extract range information
   --  from node.

   ------------------------------------------------
   -- Declare_Ada_Abstract_Signed_Int_From_Range --
   ------------------------------------------------

   procedure Declare_Ada_Abstract_Signed_Int_From_Range
      (File : W_File_Id;
       Name : String;
       Rng  : Node_Id)
   is
      Range_Node : constant Node_Id := Get_Range (Rng);
   begin
      Declare_Ada_Abstract_Signed_Int
        (File,
         Name,
         Expr_Value (Low_Bound (Range_Node)),
         Expr_Value (High_Bound (Range_Node)));
   end Declare_Ada_Abstract_Signed_Int_From_Range;

   -------------------------------
   -- Why_Logic_Type_Of_Ada_Obj --
   -------------------------------

   function Why_Logic_Type_Of_Ada_Obj (N : Node_Id)
      return W_Primitive_Type_Id is
      Ty : constant Node_Id := Etype (N);
   begin
      return New_Abstract_Type (Ty, New_Identifier (Full_Name (Ty)));
   end  Why_Logic_Type_Of_Ada_Obj;

   --------------------------------
   -- Why_Logic_Type_Of_Ada_Type --
   --------------------------------

   function Why_Logic_Type_Of_Ada_Type (Ty : Node_Id)
      return W_Primitive_Type_Id is
   begin
      return New_Abstract_Type (Ty, New_Identifier (Full_Name (Ty)));
   end  Why_Logic_Type_Of_Ada_Type;

   -------------------------------------
   -- Why_Type_Decl_Of_Full_Type_Decl --
   -------------------------------------

   procedure Why_Type_Decl_Of_Full_Type_Decl
      (File       : W_File_Id;
       Name_Str   : String;
       Ident_Node : Node_Id) is
   begin
      if Ident_Node = Standard_Boolean then
         null;
      elsif Ident_Node = Standard_Character or else
              Ident_Node = Standard_Wide_Character or else
              Ident_Node = Standard_Wide_Wide_Character then
         Declare_Ada_Abstract_Signed_Int_From_Range
           (File,
            Name_Str,
            Ident_Node);
      else
         case Ekind (Ident_Node) is
            when E_Enumeration_Type =>
               declare
                  Constructors : String_Lists.List := String_Lists.Empty_List;
                  Cur_Lit      : Entity_Id         :=
                     First_Literal (Ident_Node);
               begin
                  while Present (Cur_Lit) loop
                     Constructors.Append (Get_Name_String (Chars (Cur_Lit)));
                     Next_Literal (Cur_Lit);
                  end loop;
                  Declare_Ada_Enum_Type (File, Name_Str, Constructors);
               end;
            when E_Signed_Integer_Type
               | E_Signed_Integer_Subtype
               | E_Enumeration_Subtype =>
               Declare_Ada_Abstract_Signed_Int_From_Range
                  (File,
                   Name_Str,
                   Scalar_Range (Ident_Node));

            when E_Floating_Point_Type | E_Floating_Point_Subtype =>
               --  We do nothing here
               null;

            when Array_Kind =>
               declare
                  Comp_Type : constant String :=
                     Full_Name (Component_Type (Ident_Node));
               begin
                  if Is_Constrained (Ident_Node) then
                     declare
                        Rng            : constant Node_Id :=
                           Get_Range (First_Index (Ident_Node));
                     begin
                        Declare_Ada_Constrained_Array
                           (File,
                            Name_Str,
                            Comp_Type,
                            Expr_Value (Low_Bound (Rng)),
                            Expr_Value (High_Bound (Rng)));
                     end;
                  else
                     Declare_Ada_Unconstrained_Array
                       (File,
                        Name_Str,
                        Comp_Type);
                  end if;
               end;

            when Record_Kind =>
               declare
                  Builder : W_Logic_Type_Id;
               begin
                  Start_Ada_Record_Declaration (File,
                                                Name_Str,
                                                Builder);
                  declare
                     use String_Lists;
                     Field   : Node_Id := First_Entity (Ident_Node);
                     C_Names : List;
                  begin
                     while Present (Field) loop
                        declare
                           C_Name : constant String := Full_Name (Field);
                        begin
                           Add_Component
                             (File,
                              C_Name,
                              Why_Logic_Type_Of_Ada_Type (Etype (Field)),
                              Builder);
                           C_Names.Append (C_Name);
                           Next_Entity (Field);
                        end;
                     end loop;
                     Freeze_Ada_Record (File, Name_Str, C_Names, Builder);
                  end;
               end;

            when E_Private_Type =>

               --  This can happen when we have a private type which is
               --  derived from a private type. Simply search for the
               --  underlying type and continue.
               --  See also the comment in Alfa.Definition, for the
               --  corresponding case.

               Why_Type_Decl_Of_Full_Type_Decl
                 (File,
                  Name_Str,
                  Underlying_Type (Ident_Node));

            when others =>
               raise Not_Implemented;
         end case;
      end if;

   end Why_Type_Decl_Of_Full_Type_Decl;

   procedure Why_Type_Decl_Of_Full_Type_Decl
      (File       : W_File_Id;
       Ident_Node : Node_Id)
   is
      Name_Str : constant String := Full_Name (Ident_Node);
   begin
      Why_Type_Decl_Of_Full_Type_Decl (File, Name_Str, Ident_Node);
   end Why_Type_Decl_Of_Full_Type_Decl;

   -----------------------------------
   -- Why_Type_Decl_of_Subtype_Decl --
   -----------------------------------

   procedure Why_Type_Decl_Of_Subtype_Decl
      (File       : W_File_Id;
       Ident_Node : Node_Id)
   is
      Name_Str : constant String := Full_Name (Ident_Node);
   begin
      case Ekind (Ident_Node) is
         when Discrete_Kind =>
            --  For any subtype of a discrete type, we generate an "integer"
            --  type in Why. This is also true for enumeration types; we
            --  actually do not express that the subtype is an enumeration
            --  type, we simply state that it is in a given range.
            Declare_Ada_Abstract_Signed_Int_From_Range
              (File,
               Name_Str,
               Ident_Node);

         when Array_Kind =>
            declare
               Base : Node_Id := Ident_Node;
               Rng  : constant Node_Id :=
                  Get_Range (First_Index (Ident_Node));
            begin
               while Etype (Base) /= Base loop
                  Base := Etype (Base);
               end loop;
               --  We need to
               --    * find the Index type
               --    * find the component type
               Declare_Ada_Constrained_Array
                  (File,
                   Name_Str,
                   Full_Name (Component_Type (Base)),
                   Expr_Value (Low_Bound (Rng)),
                   Expr_Value (High_Bound (Rng)));
            end;

         when others =>
            raise Program_Error;
      end case;
   end Why_Type_Decl_Of_Subtype_Decl;

   -------------------------------
   -- Why_Prog_Type_Of_Ada_Type --
   -------------------------------

   function Why_Prog_Type_Of_Ada_Type (Ty : Node_Id; Is_Mutable : Boolean)
      return W_Simple_Value_Type_Id
   is
      Name : constant String := Full_Name (Ty);
      Base : constant W_Primitive_Type_Id :=
            New_Abstract_Type (Ty, New_Identifier (Name));
   begin
      if Is_Mutable then
         return New_Ref_Type (Ada_Node => Ty, Aliased_Type => Base);
      else
         return +Base;
      end if;
   end  Why_Prog_Type_Of_Ada_Type;

   function Why_Prog_Type_Of_Ada_Type (N : Node_Id)
      return W_Simple_Value_Type_Id
   is
   begin
      return Why_Prog_Type_Of_Ada_Type (Etype (N), Is_Mutable (N));
   end  Why_Prog_Type_Of_Ada_Type;
end Gnat2Why.Types;
