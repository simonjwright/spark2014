function Sqrt (N : Natural) return Natural
with
  Pre  => N <= 10_000,
  Post => Sqrt'Result*Sqrt'Result <= N
    and then N < (Sqrt'Result+1)*(Sqrt'Result+1)
is
   R : Natural := N;
   Y : Integer := N*N;
   Z : Integer := (-2)*N+1;
begin
   while Y > N loop
      pragma Loop_Invariant (R <= N);
      pragma Loop_Invariant (Y = R*R);
      pragma Loop_Invariant (N < (R+1)*(R+1));
      pragma Loop_Invariant (Z = (-2)*R+1);

      Y := Y+Z;
      Z := Z+2;
      R := R-1;
   end loop;

   return R;
end Sqrt;
