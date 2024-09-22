func debug_mirror_scene() -> HitableList {
    var list = [Hitable]()
    list.append(Sphere(center:Vec3(x:0, y:0, z:0), radius: 1.0,
            material: Metal(albedo: Vec3(x: 1, y: 1, z: 1), fuzz: 0.0)))
    return HitableList(list:list)
}

func debug_white_sphere_scene() -> HitableList {
    var list = [Hitable]()
    list.append(Sphere(center:Vec3(x:0, y:0, z:0), radius: 1.0,
            material: Lambertian(albedo: Vec3(x: 1, y: 0, z: 0))))
    return HitableList(list:list)
}

func debug_simple_sphere_scene() -> HitableList {
    var list = [Hitable]()
    let s = 3
    let o = -6
    for x in 0..<5 {
        for y in 0..<5 {
            for z in 0..<5 {
                let s = Sphere(center:Vec3(
                    x: Double(x * s + o), 
                    y: Double(y * s + o), 
                    z: Double(z * s + o)), 
                radius: 1, material: Lambertian(albedo: Vec3(
                    x: Double(x) / 4,
                    y: Double(y) / 4, 
                    z: Double(z) / 4)))
                list.append(s)
            }
        }
    }
    return HitableList(list:list)
}

func random_scene() -> HitableList {
    var list = [Hitable]()
    let ground_material = Lambertian(albedo:Vec3(x: 0.5, y: 0.5, z: 0.5))
    let checker = Lambertian(tex: CheckerTexture(scale: 0.32, 
        c1: Vec3(x: 0.2, y: 0.3, z: 0.1), 
        c2: Vec3(x: 0.9, y: 0.9, z: 0.9)))
    list.append(Sphere(center:Vec3(x:0, y: -1000, z:0), radius: 1000.0,
            material:checker))
    
    list.append(Sphere(center:Vec3(x:0, y:1, z:0), radius: 1.0,
            material: Dialectric(ir: 1.5)))
    list.append(Sphere(center:Vec3(x:-4, y:1, z:0), radius: 1.0,
            material: Lambertian(albedo: Vec3(x: 0.4, y: 0.2, z: 0.1))))
    list.append(Sphere(center:Vec3(x:4, y:1, z:0), radius: 1.0,
            material: Metal(albedo: Vec3(x: 0.7, y: 0.6, z: 0.5), fuzz: 0.0)))

    for a in -11...11 {
        for b in -11...11 {
            let choose_mat = Double.random(in: 0.0...1.0)
            var r = Vec3.random(in: 0.0...1.0)
            r = Vec3(x: r.x, y: 0.0, z: r.z)
            let center = 0.9 * r + Vec3(x: Double(a), y: 0.2, z: Double(b))
            
            if (center - Vec3(x: 4.0, y: 0.2, z: 0.0)).length() > 0.9 {
                let material:Material = if choose_mat < 0.8 {
                    Lambertian(albedo:
                            Vec3.random(in: 0.0...1.0) *
                            Vec3.random(in: 0.0...1.0))
                } else if choose_mat < 0.95 {
                    Metal(albedo:Vec3.random(in: 0.5...1.0),
                            fuzz: Double.random(in: 0.0...0.5))
                } else {
                    Dialectric(ir: 1.5)
                }
                if choose_mat < 0.8 {
                    let center2 = center + Vec3(x:0, y:Double.random(in: 0.0...0.5), z:0)
                    list.append(Sphere(center1:center, center2: center2, 
                        radius: 0.2, material: material))
                } else {
                    list.append(Sphere(center:center, radius: 0.2, material: material))
                }
             }
        }
    }

    return HitableList(list:list)
}

func sky_fade(_ r:Ray) -> Vec3 {
    let unit_direction = r.direction().normalize()
    let t = 0.5 * (unit_direction.y + 1.0)
    return (1.0 - t) * Vec3.one + t * Vec3(x: 0.5, y: 0.7, z: 1.0)
}

func sky_flat(_ color:Vec3) -> (Ray) -> Vec3 {
    func sky(_ r:Ray) -> Vec3 {
        return color
    }
    return sky
}

public func bouncing_spheres() {

    let config = Config(
        samples_per_pixel:50,
        max_depth:50, 
        aspect_ratio: 16.0 / 9.0, 
        image_width: 600,
        look_from: Vec3(x: 13, y: 2, z: 3),
        look_at: Vec3(x: 0, y: 0, z: 0)
    )

    let world = BVHNode(list:random_scene())
    //let world = random_scene()
    let sky = sky_fade
    //let world = BVHNode(list:debug_simple_sphere_scene())
    //let world = debug_white_sphere_scene()
    //let sky = sky_flat(Vec3(x:0.0, y:0.0, z:1.0))

    render(config:config, sky:sky,
        world:world, out_path: "/Users/jeremythorne/dev/swift-raytracing/out.tga")
}

public func checkered_spheres() {
    let config = Config(
        samples_per_pixel:100,
        max_depth:50, 
        aspect_ratio: 16.0 / 9.0, 
        image_width: 400,
        look_from: Vec3(x: 13, y: 2, z: 3),
        look_at: Vec3(x: 0, y: 1, z: 0)
    )

    var list = [Hitable]()
    let checker = Lambertian(tex: CheckerTexture(scale: 0.32, 
        c1: Vec3(x: 0.2, y: 0.3, z: 0.1), 
        c2: Vec3(x: 0.9, y: 0.9, z: 0.9)))
    list.append(Sphere(center:Vec3(x:0, y: -10, z:0), radius: 10.0,
            material:checker))
    list.append(Sphere(center:Vec3(x:0, y: 10, z:0), radius: 10.0,
            material:checker))

    let world = BVHNode(list:HitableList(list: list))
    let sky = sky_fade

    render(config:config, sky:sky,
        world:world, out_path: "/Users/jeremythorne/dev/swift-raytracing/out.tga")
}    


public func main() {
    switch(2) {
        case 1: bouncing_spheres(); break;
        case 2: checkered_spheres();
        default: checkered_spheres();
    }
}

