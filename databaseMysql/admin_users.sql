-- ============================================================
-- ElectroZoneBD - Admin Users
-- Import this in phpMyAdmin after electrobd_structure.sql
-- ============================================================
-- ADMIN CREDENTIALS:
--
--   Admin 1:
--     Email   : adminNoman@electrozonebd.com
--     Password: ElectroAdmin@2026
--
--   Admin 2:
--     Email   : superadmin_roz@electrozonebd.com
--     Password: ZoneAdmin@2026
--
--
--   Admin 3:
--     Email   : superadmin@ez.com
--     Password: ZoneAdmin@2078
--

-- ⚠️  Change passwords after first login!
-- ============================================================

USE `asiment1_electrobd`;

INSERT INTO `users`
  (`full_name`, `last_name`, `email`, `password`, `phone_number`, `gender`, `role`)
VALUES
  (
    'Admin',
    'ElectroZone',
    'adminNoman@electrozonebd.com',
    '$2b$12$de1VmFFIgH7jnxryj.7oROhywH6xqvUydHDCjInvEuy0zcEukjVTu',
    '01700000001',
    'Male',
    'admin'
  ),
  (
    'Super',
    'Admin',
    'superadmin_roz@electrozonebd.com',
    '$2b$12$1XbrSVbClXoEj160CDmjyetQFfoTZdn61PMIyqd7CeuFl/RMu1AfK',
    '01700000002',
    'Male',
    'admin'
  ),
  (
    'Super',
    'Admin',
    'superadmin@ez.com',
    '$2b$12$QaLHROlYwY3WmM40FprgsOyeU1otOI.9h0D1zcjc9yApjxgN8R2ya',
    '01700000003',
    'Male',
    'admin'
  )
ON DUPLICATE KEY UPDATE
  `password` = VALUES(`password`),
  `role`     = 'admin';
