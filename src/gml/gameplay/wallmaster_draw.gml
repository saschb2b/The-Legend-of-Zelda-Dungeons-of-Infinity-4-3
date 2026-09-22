if (!visible) exit;
draw_set_color(c_black);
draw_set_alpha(0.35);
draw_ellipse(x - 8, y - 3, x + 8, y + 2, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_sprite(sNovaWallmaster, AttackTicks > 0 ? 1 : 0, x, y - Hover - dsin(Bob) * 2);
