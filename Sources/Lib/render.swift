struct Config {
    let samples_per_pixel:Int
    let max_depth:Int
    let aspect_ratio:Double
    let image_width:Int
    let look_from: Vec3
    let look_at: Vec3
}

func render(config: Config, sky:(Ray)->Vec3,
        world:Hitable, out_path:String) {

    let camera = Camera(
        look_from: config.look_from,
        look_at: config.look_at,
        vup: Vec3(x: 0, y: 1, z: 0),
        fov: 20, 
        aspect_ratio: Double(config.aspect_ratio),
        aperture: 0.1,
        focus_dist: 10)

    let image_width = config.image_width
    let image_height = Int(Double(image_width) / config.aspect_ratio)
    var image = Image(width: image_width, height: image_height)

    let total_pixels = image_width * image_height

    for j in 0..<image_height {
        for i in 0..<image_width {
            var pixel_colour = Vec3.zero
            for _ in 0...config.samples_per_pixel {
                let a = Double.random(in: 0...1)
                let b = Double.random(in: 0...1)
                let u = (Double(i) + a) / (Double(image_width) - 1.0)
                let v = 1.0 - (Double(j) + b) / (Double(image_height) - 1.0)
                let r = camera.get_ray(s: u, t: v)
                pixel_colour = pixel_colour + ray_colour(
                    world: world, r: r, depth: config.max_depth, sky: sky)
            }
            image.set_pixel(x: i, y: j, val: write_colour(
                colour: pixel_colour, samples_per_pixel: config.samples_per_pixel))
            let percentage_complete = (j * image_width + i) * 100 / total_pixels
            print("\r\(percentage_complete) % complete\r", terminator:"") 
        }
    }
    print("")
    image.write(file: out_path)
 
}


