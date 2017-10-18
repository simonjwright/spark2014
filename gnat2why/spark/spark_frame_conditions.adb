------------------------------------------------------------------------------
--                                                                          --
--                            GNAT2WHY COMPONENTS                           --
--                                                                          --
--                S P A R K _ F R A M E _ C O N D I T I O N S               --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                     Copyright (C) 2011-2017, AdaCore                     --
--                                                                          --
-- gnat2why is  free  software;  you can redistribute  it and/or  modify it --
-- under terms of the  GNU General Public License as published  by the Free --
-- Software  Foundation;  either version 3,  or (at your option)  any later --
-- version.  gnat2why is distributed  in the hope that  it will be  useful, --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public License  distributed with  gnat2why;  see file COPYING3. --
-- If not,  go to  http://www.gnu.org/licenses  for a complete  copy of the --
-- license.                                                                 --
--                                                                          --
-- gnat2why is maintained by AdaCore (http://www.adacore.com)               --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Containers;                 use Ada.Containers;
with Ada.Containers.Hashed_Maps;
with Ada.Text_IO;                    use Ada.Text_IO;
with Lib.Xref;
with Sem_Aux;                        use Sem_Aux;
with Sem_Util;                       use Sem_Util;
with Snames;                         use Snames;
with SPARK_Xrefs;                    use SPARK_Xrefs;

package body SPARK_Frame_Conditions is

   -----------------
   -- Local Types --
   -----------------

   package Name_To_Entity_Map is new Hashed_Maps
     (Key_Type        => Entity_Name,
      Element_Type    => Entity_Id,
      Hash            => Name_Hash,
      Equivalent_Keys => "=",
      "="             => "=");

   Name_To_Entity : Name_To_Entity_Map.Map := Name_To_Entity_Map.Empty_Map;

   ---------------------
   -- Local Variables --
   ---------------------

   Defines : Node_Graphs.Map;  --  Entities defined by each scope
   Writes  : Node_Graphs.Map;  --  Entities written in each scope
   Reads   : Node_Graphs.Map;  --  Entities read in each scope
   Calls   : Node_Graphs.Map;  --  Subprograms called in each subprogram

   -----------------------
   -- Local Subprograms --
   -----------------------

   procedure Add_To_Map (Map : in out Node_Graphs.Map; From, To : Entity_Id);
   --  Add the relation From -> To in map Map

   function Make_Entity_Name (Name : String_Ptr) return Entity_Name
   with Pre => Name /= null and then Name.all /= "";
   --  Build a name for an entity, making sure the name is not empty

   procedure Set_Default_To_Empty
     (Map : in out Node_Graphs.Map;
      Id  : Entity_Id)
   with Post => Map.Contains (Id);

   --  Make sure that element Id has an entry in Map. If not already present,
   --  add one which maps the element to the empty set.

   ----------------
   -- Add_To_Map --
   ----------------

   procedure Add_To_Map (Map : in out Node_Graphs.Map; From, To : Entity_Id) is
   begin
      if not Is_Generic_Unit (From) then
         Map (From).Include (To);
      end if;
   end Add_To_Map;

   ------------------
   -- Display_Maps --
   ------------------

   procedure Display_Maps is

      use Node_Graphs;

      procedure Display_Entity (E : Entity_Id);
      procedure Display_One_Map (Map : Node_Graphs.Map; Name, Action : String);
      procedure Display_One_Set (Set : Node_Sets.Set);

      --------------------
      -- Display_Entity --
      --------------------

      procedure Display_Entity (E : Entity_Id) is
      begin
         Put ("entity " & Unique_Name (E));
      end Display_Entity;

      ---------------------
      -- Display_One_Map --
      ---------------------

      procedure Display_One_Map (Map : Node_Graphs.Map; Name, Action : String)
      is
      begin
         Put_Line ("-- " & Name & " --");

         for Cu in Map.Iterate loop
            Display_Entity (Key (Cu));
            Put_Line (" " & Action);
            Display_One_Set (Map (Cu));
         end loop;
      end Display_One_Map;

      ---------------------
      -- Display_One_Set --
      ---------------------

      procedure Display_One_Set (Set : Node_Sets.Set) is
      begin
         for Ent of Set loop
            Put ("  "); Display_Entity (Ent); New_Line;
         end loop;
      end Display_One_Set;

   --  Start of processing for Display_Maps

   begin
      Display_One_Map (Defines, "Variables defined by subprograms", "defines");
      New_Line;
      Display_One_Map (Reads, "Variables read by subprograms", "reads");
      New_Line;
      Display_One_Map (Writes, "Variables written by subprograms", "writes");
      New_Line;
      Display_One_Map (Calls, "Subprograms called", "calls");
   end Display_Maps;

   -----------------
   -- Find_Entity --
   -----------------

   function Find_Entity (E : Entity_Name) return Entity_Id is
      use Name_To_Entity_Map;
      C : constant Name_To_Entity_Map.Cursor := Name_To_Entity.Find (E);

   begin
      return (if Has_Element (C)
              then Element (C)
              else Empty);
   end Find_Entity;

   --------------------
   -- Computed_Calls --
   --------------------

   function Computed_Calls (E : Entity_Id) return Node_Sets.Set
     renames Calls.Element;

   --------------------
   -- Computed_Reads --
   --------------------

   function Computed_Reads (E : Entity_Id) return Node_Sets.Set
   is
      pragma Assert (if Ekind (E) = E_Entry then No (Alias (E)));
      --  Alias is empty for entries and meaningless for entry families

      E_Alias : constant Entity_Id :=
        (if Ekind (E) in E_Function | E_Procedure
           and then Present (Alias (E))
         then Ultimate_Alias (E)
         else E);

      Read_Ids : Node_Sets.Set;

      use type Node_Sets.Set;

   begin
      --  ??? Abstract subprograms not yet supported. Avoid issuing an error on
      --  those, instead return empty sets.

      if Is_Subprogram_Or_Entry (E)
        and then Ekind (E) /= E_Entry_Family
        and then Is_Abstract_Subprogram (E_Alias)
      then
         return Node_Sets.Empty_Set;
      end if;

      Read_Ids := Reads (E_Alias);

      return Read_Ids - Defines (E_Alias);
   end Computed_Reads;

   ---------------------
   -- Computed_Writes --
   ---------------------

   function Computed_Writes (E : Entity_Id) return Node_Sets.Set is
      pragma Assert (if Ekind (E) = E_Entry then No (Alias (E)));
      --  Alias is empty for entries and meaningless for entry families

      E_Alias : constant Entity_Id :=
        (if Ekind (E) in E_Function | E_Procedure
           and then Present (Alias (E))
         then Ultimate_Alias (E)
         else E);

      Write_Ids : Node_Sets.Set;

      use type Node_Sets.Set;

   begin
      --  ??? Abstract subprograms not yet supported. Avoid issuing an error on
      --  those, which do not have effects, instead return the empty set.

      if Is_Subprogram_Or_Entry (E)
        and then Ekind (E) /= E_Entry_Family
        and then Is_Abstract_Subprogram (E_Alias)
      then
         return Node_Sets.Empty_Set;
      end if;

      --  Go through the reads and check if the entities corresponding to
      --  variables (not constants) have pragma Effective_Reads set. If so,
      --  then these entities are also writes.
      --  ??? call to Computed_Reads repeats what is already done here; this
      --  should be refactored.
      for Read of Computed_Reads (E) loop
         if Present (Read)
           and then Ekind (Read) = E_Variable
           and then Present (Get_Pragma (Read, Pragma_Effective_Reads))
         then
            Write_Ids.Insert (Read);
         end if;
      end loop;

      Write_Ids.Union (Writes (E_Alias));

      return Write_Ids - Defines (E_Alias);
   end Computed_Writes;

   ----------------------
   -- Is_Heap_Variable --
   ----------------------

   function Is_Heap_Variable (Ent : Entity_Name) return Boolean is
     (To_String (Ent) = SPARK_Xrefs.Name_Of_Heap_Variable);

   function Is_Heap_Variable (E : Entity_Id) return Boolean is
     (E = SPARK_Xrefs.Heap);

   ----------------------
   -- Load_SPARK_Xrefs --
   ----------------------

   procedure Load_SPARK_Xrefs is

      function Def_Scope_Ent (E : Entity_Id) return Entity_Id;
      --  For entity E, which represents an object, returns the entity of the
      --  unit where that object is declared.

      -------------------
      -- Def_Scope_Ent --
      -------------------

      function Def_Scope_Ent (E : Entity_Id) return Entity_Id is
        (Unique_Entity
          (Lib.Xref.SPARK_Specific.
             Enclosing_Subprogram_Or_Library_Package (E)));

      Current_Entity : Entity_Id := Empty;

   --  Start of processing for Load_SPARK_Xrefs

   begin
      --  Fill Scopes, i.e scopes in this compilation unit

      for F in SPARK_File_Table.First .. SPARK_File_Table.Last loop
         for S in SPARK_File_Table.Table (F).From_Scope
           .. SPARK_File_Table.Table (F).To_Scope
         loop
            declare
               Srec : SPARK_Scope_Record renames SPARK_Scope_Table.Table (S);
               U    : constant Entity_Id := Unique_Entity (Srec.Entity);
               --  ??? Unique_Entity is required here for subprograms declared
               --  by stubs; probably frontend xrefs should special-case them.
            begin
               Set_Default_To_Empty (Defines, U);
               Set_Default_To_Empty (Writes,  U);
               Set_Default_To_Empty (Reads,   U);
               Set_Default_To_Empty (Calls,   U);
            end;
         end loop;
      end loop;

      --  Fill in high-level tables from xrefs

      for F in SPARK_File_Table.First .. SPARK_File_Table.Last
      loop
         for S in SPARK_File_Table.Table (F).From_Scope ..
           SPARK_File_Table.Table (F).To_Scope
         loop
            for X in SPARK_Scope_Table.Table (S).From_Xref ..
              SPARK_Scope_Table.Table (S).To_Xref
            loop
               Do_One_Xref : declare

                  Xref : SPARK_Xref_Record renames SPARK_Xref_Table.Table (X);

                  Ref_Entity : Entity_Id renames Xref.Entity;
                  --  Referenced entity

                  Ref_Scope_Ent : constant Entity_Id :=
                    Unique_Entity (Xref.Ref_Scope);
                  --  Scope where the reference occurs

               begin
                  --  Register the definition on first occurence of
                  --  variables.

                  if Current_Entity /= Ref_Entity
                    and then not Is_Heap_Variable (Ref_Entity)
                    and then Xref.Rtype in 'r' | 'm'
                  then
                     Add_To_Map (Defines,
                                 Def_Scope_Ent (Ref_Entity),
                                 Ref_Entity);
                  end if;

                  --  Register xref according to type

                  case Xref.Rtype is
                     when 'r' =>
                        Add_To_Map (Reads,  Ref_Scope_Ent, Ref_Entity);
                     when 'm' =>
                        Add_To_Map (Writes, Ref_Scope_Ent, Ref_Entity);
                     when 's' =>
                        Add_To_Map (Calls,  Ref_Scope_Ent, Ref_Entity);
                     when others =>
                        raise Program_Error;
                  end case;

                  Current_Entity := Ref_Entity;
               end Do_One_Xref;
            end loop;
         end loop;
      end loop;
   end Load_SPARK_Xrefs;

   ----------------------
   -- Make_Entity_Name --
   ----------------------

   function Make_Entity_Name (Name : String_Ptr) return Entity_Name is
     (To_Entity_Name (Name.all));

   ---------------------
   -- Register_Entity --
   ---------------------

   procedure Register_Entity (E : Entity_Id) is
      E_Name : constant Entity_Name := To_Entity_Name (E);
   begin
      Name_To_Entity.Include (E_Name, E);
   end Register_Entity;

   --------------------------
   -- Set_Default_To_Empty --
   --------------------------

   procedure Set_Default_To_Empty
     (Map : in out Node_Graphs.Map;
      Id  : Entity_Id)
   is
      Inserted : Boolean;
      Position : Node_Graphs.Cursor;
      --  Dummy variables required by the container API

   begin
      Map.Insert (Key      => Id,
                  Position => Position,
                  Inserted => Inserted);
      --  Attempt to map entity Ent to a default element (i.e. empty set)
   end Set_Default_To_Empty;

   -------------------------------------
   -- Collect_Direct_Computed_Globals --
   -------------------------------------

   procedure Collect_Direct_Computed_Globals
     (E       :     Entity_Id;
      Inputs  : out Node_Sets.Set;
      Outputs : out Node_Sets.Set)
   is
      pragma Assert (if Ekind (E) = E_Entry then No (Alias (E)));
      --  Alias is empty for entries and meaningless for entry families

      E_Alias : constant Entity_Id :=
        (if Ekind (E) in E_Function | E_Procedure
           and then Present (Alias (E))
         then Ultimate_Alias (E)
         else E);

   begin
      --  ??? Abstract subprograms not yet supported. Avoid issuing an error on
      --  those, instead return empty sets.

      if Is_Subprogram_Or_Entry (E)
        and then Ekind (E) /= E_Entry_Family
        and then Is_Abstract_Subprogram (E_Alias)
      then
         --  Initialize to empty sets and return
         Inputs  := Node_Sets.Empty_Set;
         Outputs := Node_Sets.Empty_Set;

         return;
      end if;

      Inputs  := Computed_Reads (E);
      Outputs := Computed_Writes (E);

      --  Add variables written to variables read
      --  ??? for composite variables fine, but why for simple ones?
      Inputs.Union (Outputs);
   end Collect_Direct_Computed_Globals;

end SPARK_Frame_Conditions;
