import Foundation // for tan()

struct Camera {
    let origin: Vec3
    let lower_left_corner: Vec3
    let horizontal: Vec3
    let vertical: Vec3
    let u: Vec3
    let v: Vec3
    let w: Vec3
    let lens_radius: Double

    init(look_from:Vec3,
            look_at:Vec3,
            vup:Vec3,
            fov:Double, 
            aspect_ratio:Double,
            aperture:Double,
            focus_dist:Double
            ) {
        let theta = fov * Double.pi / 180.0
        let h = tan(theta / 2.0)
        let viewport_height = 2.0 * h
        let viewport_width = aspect_ratio * viewport_height

        self.w = (look_from - look_at).normalize()
        self.u = vup.cross(w).normalize()
        self.v = w.cross(u)

        self.lens_radius = aperture / 2.0

        self.origin = look_from
        self.horizontal = focus_dist * viewport_width * u
        self.vertical = focus_dist * viewport_height * v
        self.lower_left_corner = origin - 0.5 * (horizontal + vertical) - focus_dist * w
    }

    func get_ray(s:Double, t:Double) -> Ray {
        let rd = random_in_unit_disk() * lens_radius 
        let offset = u * rd.x + v * rd.y
        let ray_time = Double.random(in: 0.0...1.0)
        return Ray( a: origin + offset,
                    b: lower_left_corner +
                        s * horizontal +
                        t * vertical -
                        origin -
                        offset,
                    tm: ray_time)
    }
}
