#define FAR_DISTANCE 1000000.0
#define SPHERE_COUNT 2

vec2 viewport(vec2 pos, vec2 screen) {
    return vec2(
        2. * (pos.x + .5) / screen.x - 1.,
        2. * (pos.y + .5) / screen.y - 1.
    );
}

vec2 perspective(vec2 pos, vec2 screen) {
    float fov = 2.;
    float ar = screen.x / screen.y;
    return vec2(
        pos.x * tan(fov / 2.) * ar,
        pos.y * tan(fov / 2.)
    );
}

struct Material {
    vec3 emmitance;
    vec3 reflectance;
    float roughness;
    float opacity;
};

struct Sphere {
    vec3 pos;
    float r;
    Material mat
};

Sphere spheres[SPHERE_COUNT];

bool intersectSphere(vec3 ray, Sphere sph, out vec3 d, out vec3 n) {
    float a = 1.;
    float b = -2.*dot(ray, sph.pos);
    float c = dot(sph.pos, sph.pos) - sph.r*sph.r;
    float d = b*b - 4.*a*c;
    if (d < 0.) {
        return false;
    }
    d = (-b + sqrt(d)) / 2.;
    // float x2 = (-b + sqrt(d)) / 2.;
    n = d * ray - sph.pos;
    return true;
}

bool castRay(vec3 ray, ) {
    float minDist = FAR_DISTANCE;
    vec3 norm;
    for (int i = 0; i < SPHERE_COUNT; i++) {
        Sphere sph = spheres[i];
        float d;
        vec3 n;
        if (intersectSphere(ray, sph, d, n) && d < minDist) {
            minDist = d;
            norm = n;
        } 
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float w = iResolution.x;
    float h = iResolution.y;
    
    vec3 cam = normalize(vec3(
        perspective(
            viewport(fragCoord.xy, iResolution.xy),
            iResolution.xy
        ),
        -1.
    ));
    
    Sphere sph = Sphere(vec3(0., 0., -2.), 1.);
    vec3 dst;

    fragColor = vec4(.1, .1, .1, 1.);

    if (intersectSphere(cam, sph, d, n)) {
        vec3 light = vec3(-1., 1., -1.);
        vec3 n = dst - sph.pos;
        
        fragColor = dot(light, n)* vec4(0.3, 0.2, 0.4, 1.);
    }
}
