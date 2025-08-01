function circleIntersection(c1_origin, c1_radius, c2_radius, c2_origin) {
    local distance = sqrt(pow(c2_origin.x - c1_origin.x, 2) + pow(c2_origin.y - c1_origin.y, 2))
    return distance < c1_radius + c2_radius
}

function lineIntersection(circle_center, circle_radius, line_origin, line_length, line_angle_degrees) {
    local angle_radians = line_angle_degrees.y * (PI / 180)

    local half_length = line_length / 2

    local dx = half_length * cos(angle_radians)
    local dy = half_length * sin(angle_radians)

    local start_point = {x = line_origin.x - dx, y = line_origin.y - dy}
    local end_point = {x = line_origin.x + dx, y = line_origin.y + dy}

    local line_vector = {x = end_point.x - start_point.x, y = end_point.y - start_point.y}

    local center_vector = {x = circle_center.x - start_point.x, y = circle_center.y - start_point.y}

    local dot_product = center_vector.x * line_vector.x + center_vector.y * line_vector.y
    local line_vector_squared = pow(line_vector.x, 2) + pow(line_vector.y, 2)

    local t = dot_product / line_vector_squared

    if (t < 0) {
        t = 0
    }
    else if (t > 1) {
        t = 1
    }

    local closest_point = {
        x = start_point.x + t * line_vector.x,
        y = start_point.y + t * line_vector.y
    }

    local dx_closest = circle_center.x - closest_point.x
    local dy_closest = circle_center.y - closest_point.y
    local distance_squared = pow(dx_closest, 2) + pow(dy_closest, 2)

    return distance_squared <= pow(circle_radius, 2)
}