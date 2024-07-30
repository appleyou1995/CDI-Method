function y = OBJ_BS_Cubic(x, h, x_np)

    y = 0;
    
    if (x > x_np(1)) && (x <= x_np(2))
        y = power(6 * power(h, 3), - 1) * ...
            power(x - x_np(1), 3);
    else
    end
    
    if (x > x_np(2)) && (x <= x_np(3))
        y = 2 / 3 - ...
            power(2 * power(h, 3), - 1) * ...
            power(x - x_np(1), 1) * ...
            power(x_np(3) - x, 2);
    else
    end
    
    if (x > x_np(3)) && (x <= x_np(4))
        y = 2 / 3 - ...
            power(2 * power(h, 3), - 1) * ...
            power(x_np(5) - x, 1) * ...
            power(x - x_np(3), 2);
    else
    end
    
    if (x > x_np(4)) && (x <= x_np(5))
        y = power(6 * power(h, 3), - 1) * ...
            power(x_np(5) - x, 3);
    end

end