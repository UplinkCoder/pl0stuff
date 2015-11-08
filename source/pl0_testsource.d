static immutable test0 =
`CONST n = 7, m = 85;
VAR x,y,z,q,r;
CALL end
.`;

static immutable test1 =
	`PROCEDURE fib;
	BEGIN	
	!a;
	!b
	END;

BEGIN
! n;
CALL end
END
.`;

static immutable test0_extended =
`        CONST one = 1;
        VAR x , squ , y ;
        PROCEDURE superflous;
                squ := squ
        ;
        PROCEDURE square;
                BEGIN
                        squ := x * x
                END
        ;

        BEGIN
                BEGIN
                        x := one;
                        CALL superflous
                END;
                WHILE x <= 10 DO
                BEGIN
                        CALL square;
                        ! squ;
                        x := x + one
                END
        END

.
.`;

static immutable test1_extended =
`
PROCEDURE fib;
	ARG a0, a1;
	BEGIN	
	!a;
	!b
	END;

BEGIN
! n;
! 7.7;
CALL fib ARG 1, 2.2
END
.`;

static immutable test2_extended = 
`
CONST
  m =  7,
  n = 85;

VAR
  x, y, z, q, r;

PROCEDURE multiply;
VAR a, b;

BEGIN
  a := x;
  b := y;
  z := 0;
  WHILE b > 0 DO BEGIN
    IF ODD b THEN z := z + a;
    a := 2 * a;
    b := b / 2
  END;
  ! z
END;

PROCEDURE divide;
VAR w;
BEGIN
  r := x;
  q := 0;
  w := y;
  WHILE w <= r DO w := 2 * w;
  WHILE w > y DO BEGIN
    q := 2 * q;
    w := w / 2;
    IF w <= r THEN BEGIN
      r := r - w;
      q := q + 1
    END
  END;
  ! q;
  ! r
END;

PROCEDURE gcd;
VAR f, g;
BEGIN
  f := x;
  g := y;
  WHILE f # g DO BEGIN
    IF f < g THEN g := g - f;
    IF g < f THEN f := f - g
  END;
  z := f;
  ! z
END;

BEGIN
  x := m;
  y := n;
  CALL multiply;
  x := 25;
  y :=  3;
  CALL divide;
  x := 84;
  y := 36;
  CALL gcd
END.
`;