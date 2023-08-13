// This file contains functions related to bezier curve calculation
#import "vector.typ"

/// Get point on quadratic bezier at position t
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c (vector): Control point
/// - t (float): Position on curve [0, 1]
/// -> vector
#let quadratic-point(a, b, c, t) = {
  // (1-t)^2 * a + 2 * (1-t) * t * c + t^2 b
  return vector.add(
    vector.add(
      vector.scale(a, calc.pow(1-t, 2)),
      vector.scale(c, 2 * (1-t) * t)
    ),
    vector.scale(b, calc.pow(t, 2))
  )
}

/// Get dx/dt of quadratic bezier at position t
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c (vector): Control point
/// - t (float): Position on curve [0, 1]
/// -> vector
#let quadratic-derivative(a, b, c, t) = {
  // 2(-a(1-t) + bt - 2ct + c)
  return vector.scale(
    vector.add(
      vector.sub(
        vector.add(
          vector.scale(vector.neg(a), (1 - t)),
          vector.scale(b, t)),
        vector.scale(c, 2 * t)),
      c)
  , 2)
}

/// Get point on cubic bezier curve at position t
///
/// - a (vector):  Start point
/// - b (vector):  End point
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - t (float):   Position on curve [0, 1]
/// -> vector
#let cubic-point(a, b, c1, c2, t) = {
  // (1-t)^3*a + 3*(1-t)^2*t*c1 + 3*(1-t)*t^2*c2 + t^3*b
  vector.add(
    vector.add(
      vector.scale(a, calc.pow(1-t, 3)),
      vector.scale(c1, 3 * calc.pow(1-t, 2) * t)
    ),
    vector.add(
      vector.scale(c2, 3*(1-t)*calc.pow(t,2)),
      vector.scale(b, calc.pow(t, 3))
    )
  )
}

/// Get dx/dt of cubic bezier at position t
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - t (float): Position on curve [0, 1]
/// -> vector
#let cubic-derivative(a, b, c1, c2, t) = {
  // -3(a(1-t)^2 + t(-2c2 - bt + 3 c2 t) + c1(-1 + 4t - 3t^2))
  vector.scale(
    vector.add(
      vector.add(
        vector.scale(a, calc.pow((1 - t), 2)),
        vector.scale(
          vector.sub(
            vector.add(
              vector.scale(b, -1 * t),
              vector.scale(c2, 3 * t)
            ),
            vector.scale(c2, 2)
          ),
          t
        )
      ),
      vector.scale(c1, -3 * calc.pow(t, 2) + 4 * t - 1)
    ),
    -3
  )
}

/// Get bezier curves ABC coordinates
///
///        /A\  <-- Control point of quadratic bezier
///       / | \
///      /  |  \
///     /_.-B-._\  <-- Point on curve
///    ,'   |   ',
///   /     |     \
///  s------C------e  <-- Point on line between s and e
///
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - B (vector): Point on curve
/// - t (fload): Position on curve [0, 1]
/// - deg (int): Bezier degree (2 or 3)
/// -> (tuple) Tuple of A, B and C vectors
#let to-abc(s, e, B, t, deg: 2) = {
  let tt = calc.pow(t, deg)
  let u(t) = {
    (calc.pow(1 - t, deg) /
     (tt + calc.pow(1 - t, deg)))
  }
  let ratio(t) = {
    calc.abs((tt + calc.pow(1 - t, deg) - 1) /
             (tt + calc.pow(1 - t, deg)))
  }

  let C = vector.add(vector.scale(s, u(t)), vector.scale(e, 1 - u(t)))
  let A = vector.sub(B, vector.scale(vector.sub(C, B), 1 / ratio(t)))

  return (A, B, C)
}


/// Compute control points for quadratic bezier through 3 points
///
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - B (vector): Point on curve
///
/// -> (s, e, c) Cubic bezier curve points
#let quadratic-through-3points(s, B, e) = {
  let d1 = vector.dist(s, B)
  let d2 = vector.dist(e, B)
  let t = d1 / (d1 + d2)

  let (A, B, C) = to-abc(s, e, B, t, deg: 2)

  return (s, e, A)
}

/// Compute control points for cubic bezier through 3 points
///
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - B (vector): Point on curve
///
/// -> (s, e, c1, c2) Cubic bezier curve points
#let cubic-through-3points(s, B, e) = {
  let d1 = vector.dist(s, B)
  let d2 = vector.dist(e, B)
  let t = d1 / (d1 + d2)

  let (A, B, C) = to-abc(s, e, B, t, deg: 3)

  let d = vector.sub(B, C)
  if vector.len(d) == 0 {
    return (s, e, s, e)
  }

  d = vector.norm(d)
  d = (-d.at(1), d.at(0))
  d = vector.scale(d, vector.dist(s, e) / 3)
  let c1 = vector.add(A, vector.scale(d, t))
  let c2 = vector.sub(A, vector.scale(d, (1 - t)))

  let is-right = ((e.at(0) - s.at(0))*(B.at(1) - s.at(1)) -
                  (e.at(1) - s.at(1))*(B.at(0) - s.at(0))) < 0
  if is-right {
    (c1, c2) = (c2, c1)
  }

  return (s, e, c1, c2)
}
