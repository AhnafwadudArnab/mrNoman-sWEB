-- ============================================================
-- Run this SQL in cPanel phpMyAdmin -> SQL tab
-- ============================================================

-- 1. Reassign any existing orders from old admin to prevent FK error
UPDATE `orders` SET `user_id` = NULL WHERE `user_id` IN (SELECT `user_id` FROM (SELECT `user_id` FROM `users` WHERE `email` = 'admin@electrozonebd.com') AS tmp);

-- 2. Delete old default admin (admin@electrozonebd.com)
DELETE FROM `users` WHERE `email` = 'admin@electrozonebd.com';

-- 3. Add or update the 3 new admin accounts
INSERT INTO `users` (`full_name`, `email`, `password`, `role`, `phone_number`, `gender`)
VALUES ('Admin Noman', 'adminNoman@electrozonebd.com', '$2y$12$a7kL/Ajes1T7GY1NDa4FEOEaz06Ag2QGTmsUjPxcoBUWK8QkCqM8O', 'admin', '01700000001', 'Male')
ON DUPLICATE KEY UPDATE `password` = '$2y$12$a7kL/Ajes1T7GY1NDa4FEOEaz06Ag2QGTmsUjPxcoBUWK8QkCqM8O', `role` = 'admin', `full_name` = 'Admin Noman';

INSERT INTO `users` (`full_name`, `email`, `password`, `role`, `phone_number`, `gender`)
VALUES ('Super Admin Roz', 'superadmin_roz@electrozonebd.com', '$2y$12$V3IrAHgZLqrt7vGLJKJEwOAJpFE4M23O1KPffzJ93XMe9XPrQIfwK', 'admin', '01700000002', 'Male')
ON DUPLICATE KEY UPDATE `password` = '$2y$12$V3IrAHgZLqrt7vGLJKJEwOAJpFE4M23O1KPffzJ93XMe9XPrQIfwK', `role` = 'admin', `full_name` = 'Super Admin Roz';

INSERT INTO `users` (`full_name`, `email`, `password`, `role`, `phone_number`, `gender`)
VALUES ('Super Admin EZ', 'superadmin@ez.com', '$2y$12$dX/BFd4P7Y/nsH1C21E18.b0WOfBICLCauJNaV3PH8yfMJxc658b2', 'admin', '01700000003', 'Male')
ON DUPLICATE KEY UPDATE `password` = '$2y$12$dX/BFd4P7Y/nsH1C21E18.b0WOfBICLCauJNaV3PH8yfMJxc658b2', `role` = 'admin', `full_name` = 'Super Admin EZ';

