func random_in_unit_sphere() -> Vec3 {
    while true {
        let p = Vec3.random(in: -1.0...1.0)
        if p.length_squared() <= 1.0 {
            return p
        }
    }
}

func random_unit_vector() -> Vec3 {
    return random_in_unit_sphere().normalize()
}

func random_in_unit_disk() -> Vec3 {
    while true {
        var p = Vec3.random(in: -1.0...1.0)
        p = Vec3(x:p.x, y: p.y, z: 0.0)
        if p.length_squared() <= 1.0 {
            return p;
        }
    }
}

func near_zero(v: Vec3) -> Bool {
    let e:Double = 1e-8
    return abs(v.x) < e && abs(v.y) < e && abs(v.z) < e
}

func reflect(_ a: Vec3, _ b:Vec3) -> Vec3 {
    a - 2.0 * a.dot(b) * b
}

func refract(_ uv: Vec3, _ n: Vec3, _ etai_over_etat: Double) -> Vec3 {
    let cos_theta = min((-uv).dot(n), 1.0)
    let r_out_perp = etai_over_etat * (uv + cos_theta * n)
    let r_out_parallel = -abs(1.0 - r_out_perp.length_squared()).squareRoot() * n
    return r_out_perp + r_out_parallel
}

func ray_colour(world: Hitable, r: Ray, depth: Int, sky: (Ray)->Vec3) -> Vec3 {
    if depth < 0 {
        return Vec3.zero
    }

    if let rec = world.hit(r: r, ray_t:Interval(t_min: 0.001, t_max: Double.infinity)) {
        if let scattered = rec.material.scatter(r: r, rec: rec) {
            return scattered.attenuation *
                    ray_colour(world: world, r: scattered.ray, depth: depth - 1, sky: sky)
        } else {
            return Vec3.zero
        }
    }
    return sky(r)
}

func write_colour(colour:Vec3, samples_per_pixel:Int) -> (UInt8, UInt8, UInt8) {
    let scale = 1.0 / Double(samples_per_pixel)
    let scaled = colour * scale
    let gamma_corrected = Vec3(x:  scaled.x.squareRoot(),
                                y: scaled.y.squareRoot(),
                                z: scaled.z.squareRoot())
    let two55 = 255.0 * gamma_corrected.clamp(vmin: Vec3.zero, vmax: Vec3.one)
    return (
        UInt8(two55.x),
        UInt8(two55.y),
        UInt8(two55.z)
    )
}
