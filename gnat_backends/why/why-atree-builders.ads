------------------------------------------------------------------------------
--                                                                          --
--                            GNAT2WHY COMPONENTS                           --
--                                                                          --
--                   W H Y - A T R E E - B U I L D E R S                    --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
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

with Why.Atree.Tables; use Why.Atree.Tables;

package Why.Atree.Builders is
   --  This package provides a set of unchecked builders, generated
   --  automatically from Why.Atree.Why_Node using an ASIS tool...
   --  with the exception of preconditions, which should be added by
   --  hand.

   --  ??? This is just a rudimentary sample of what this would look like...
   --  to give some food for thought in designing this backend.

   function New_Identifier
     (Ada_Node        : Node_Id;
      Link            : Why_Node_Id;
      Symbol          : Name_Id;
      Entity          : Why_Node_Id := Why_Empty)
     return Why_Node_Id;
   pragma Postcondition (Get_Node (New_Identifier'Result)
                         = Why_Node'(Kind => W_Identifier,
                                     Ada_Node => Ada_Node,
                                     Link => Link,
                                     Symbol => Symbol,
                                     Entity => Entity));
   pragma Inline (New_Identifier);

   function New_Type
     (Ada_Node        : Node_Id;
      Link            : Why_Node_Id;
      External        : Why_Node_Id := Why_Empty;
      Type_Parameters : Why_Node_List := Why_Empty_List;
      Name            : Why_Node_Id)
     return Why_Node_Id;
   pragma Precondition (Option (External, W_External)
                        and then Get_Kind (Name) = W_Identifier);
   pragma Postcondition (Get_Node (New_Type'Result)
                         = Why_Node'(Kind => W_Type,
                                     Ada_Node => Ada_Node,
                                     Link => Link,
                                     T_External => External,
                                     T_Type_Parameters => Type_Parameters,
                                     T_Name => Name));
   pragma Inline (New_Type);

end Why.Atree.Builders;
