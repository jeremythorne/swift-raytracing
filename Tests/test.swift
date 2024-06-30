import XCTest
import Lib

class Tests : XCTestCase {
    func test_vec3_length() {
        XCTAssertEqual(5.0, Vec3(x:3.0, y:4.0, z:0.0).length())
    }

    func test_vec3_mul() {
        let a = Vec3(x: 1.0, y: 2.0, z: 3.0) * 3.0
        let b = Vec3(x: 3.0, y: 6.0, z: 9.0)
        XCTAssertEqual(a, b)
    }

    func test_interval() {
        let a = Interval(t_min: -1.0, t_max: 1.0)
        let b = Interval(t_min: 2.0, t_max: 3.0)
        let c = Interval(a:a, b: b)
        XCTAssertEqual(c, Interval(t_min: -1.0, t_max: 3.0))
    }

    func test_aabb_empty() {
        let a = AABB()
        let b = AABB(a: Vec3(x: -1.0, y: -2.0, z: -3.0), b: Vec3(x: 1.0, y: 2.0, z: 3.0))
        let c = AABB(box0: b, box1: a)
        XCTAssertEqual(c.x, Interval(t_min:-1.0, t_max:1.0))
        XCTAssertEqual(c.y, Interval(t_min:-2.0, t_max:2.0))
        XCTAssertEqual(c.z, Interval(t_min:-3.0, t_max:3.0))
    }

    func test_aabb_combine() {
        let a = AABB(a: Vec3(x: -5.0, y: -6.0, z: -7.0), b: Vec3(x: -4.0, y: -4.0, z: -4.0))
        let b = AABB(a: Vec3(x: -1.0, y: -2.0, z: -3.0), b: Vec3(x: 1.0, y: 2.0, z: 3.0))
        let c = AABB(box0: b, box1: a)
        XCTAssertEqual(c, 
            AABB(a: Vec3(x: -5.0, y: -6.0, z: -7.0), b: Vec3(x: 1.0, y: 2.0, z: 3.0)))
    }

    func test_aabb_hit() {
        let a = AABB(a: Vec3(x: -5.0, y: -5.0, z: -5.0), b: Vec3(x: -4.0, y: -4.0, z: -4.0))
        let r = Ray(a: Vec3(x: -4.5, y: -4.5, z: 0.0), b: Vec3(x: 0.0, y: 0.0, z: -10.0))
        // offset origin
        let r2 = Ray(a: Vec3(x: -14.5, y: -14.5, z: 0.0), b: Vec3(x: 0.0, y: 0.0, z: -10.0))
        // right origin, direction, but too short
        let r3 = Ray(a: Vec3(x: -4.5, y: -4.5, z: 0.0), b: Vec3(x: 0.0, y: 0.0, z: -1.0))
        // ray parallel to x axis
        let r_x = Ray(a: Vec3(x: 0.0, y: -4.5, z: -4.5), b: Vec3(x: -10.0, y: 0.0, z: 0.0))
        // ray parallel to y axis
        let r_y = Ray(a: Vec3(x: -4.5, y: 0, z: -4.5), b: Vec3(x: 0, y: -10, z: 0))
        let interval = Interval(t_min:0.0, t_max:1.0)
        XCTAssertEqual(a.hit(r:r, ray_t:interval), true)
        XCTAssertEqual(a.hit(r:r2, ray_t:interval), false)
        XCTAssertEqual(a.hit(r:r3, ray_t:interval), false)
        XCTAssertEqual(a.hit(r:r_x, ray_t:interval), true)
        XCTAssertEqual(a.hit(r:r_y, ray_t:interval), true)
    }

    func test_sphere_aabb() {
        let s = Sphere(center:Vec3(x: 4, y: 4, z: 4), radius: 3, material: Lambertian(albedo: Vec3.one))
        let b = s.bounding_box()
        XCTAssertEqual(b, AABB(a: Vec3(x: 1, y: 1, z: 1), b: Vec3(x: 7, y: 7, z: 7)))
    }

    func test_bvh_simple() {
        let s = Sphere(center:Vec3(x: 4, y: 4, z: 4), radius: 3, material: Lambertian(albedo: Vec3.one))
        let bvh = BVHNode(list:[s])
        let r = Ray(a: Vec3(x: 4, y: 4, z: 0), b: Vec3(x: 0, y: 0, z: 5))
        let interval = Interval(t_min:0, t_max:1)
        let h = bvh.hit(r:r, ray_t:interval)
        XCTAssertEqual(h != nil, true)
    }

    func test_bvh() {
        let pattern = [
            1, 1, 0,
            0, 1, 0,
            1, 0, 0,
        ]
        var objs = [Hitable]()
        for i in 0..<9 {
            if pattern[i] == 1 {
                let x = Float(i % 3)
                let y = Float(i / 3)
                let s = Sphere(center:Vec3(x: x, y: y, z: 0.5), 
                    radius: 1, material: Lambertian(albedo: Vec3.one))
                objs.append(s) 
            }
        }
        let bvh = BVHNode(list: objs[...])
        let interval = Interval(t_min:0, t_max:1)
        for i in 0..<9 {
            let x = Float(i % 3)
            let y = Float(i / 3)
            let r = Ray(a: Vec3(x: x, y: y, z: 0), b: Vec3(x: 0, y: 0, z: 2))
            let h = bvh.hit(r:r, ray_t:interval)
            XCTAssertEqual(h != nil, pattern[i] == 1)
        }         
    }
}
