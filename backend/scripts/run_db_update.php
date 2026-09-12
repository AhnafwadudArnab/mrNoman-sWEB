<?php
header('Content-Type: application/json');

require_once __DIR__ . '/../config/db.php';

try {
    $db = (new Database())->getConnection();
    if (!$db) {
        echo json_encode(['success' => false, 'error' => 'Database connection returned null']);
        exit;
    }

    // Fetch valid categories
    $catStmt = $db->query("SELECT category_id FROM categories");
    $validCategories = $catStmt->fetchAll(PDO::FETCH_COLUMN, 0);

    $updates = [
        [
            'id' => 10,
            'name' => 'Hikvision Turbo HD CCTV Surveillance Kit',
            'desc' => 'High-definition 8-camera surveillance kit with Turbo HD DVR, night vision, weatherproof cameras, and remote viewing capabilities.',
            'category_id' => 4,
            'image_url' => null,
        ],
        [
            'id' => 12,
            'name' => 'Haeger Stainless Steel Rice Cooker & Steamer 5L',
            'desc' => 'Large 5L stainless steel electric rice cooker with keep-warm function, non-stick inner pot, and vegetable steaming basket.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 13,
            'name' => 'Hamilton 8" Rechargeable Table Fan with LED Light',
            'desc' => 'Compact 8-inch rechargeable table fan with bright LED light, multi-speed airflow, and long-lasting backup battery for power outages.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 14,
            'name' => 'Walton 1.5 Ton Inverter Air Conditioner',
            'desc' => 'Energy-efficient 1.5 ton split air conditioner with ProGen inverter technology, fast cooling, auto-restart, and sleep mode.',
            'category_id' => 3,
            'image_url' => 'assets/prod/6.png',
        ],
        [
            'id' => 15,
            'name' => 'Jamuna Electric Rice Cooker 2.8L with Steamer',
            'desc' => 'High quality Jamuna royal blue electric rice cooker 2.8L with stainless steel steamer tray, extra inner pot, and 1-year warranty.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 16,
            'name' => 'Stainless Steel Electric Spice & Coffee Grinder',
            'desc' => 'Multi-purpose stainless steel electric spice and coffee grinder with push-down safety lid and sharp stainless steel blades.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 17,
            'name' => 'Nova 3-in-1 Blender Mixer & Grinder 870W',
            'desc' => 'High-power 870W copper motor with 3 heavy-duty stainless steel jars for multi-purpose blending, wet grinding, and dry spice grinding.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 19,
            'name' => 'Mini Handheld Cat-Ear Portable Fan',
            'desc' => 'Adorable cat-ear rechargeable pocket fan with quiet multi-speed airflow, ergonomic handle, and USB charging.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 21,
            'name' => 'Cat-Ear Cute Rechargeable Handheld Pocket Fan',
            'desc' => 'Ultra-portable pocket fan with cute cat ears, USB rechargeable battery, and smooth quiet breeze.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 22,
            'name' => 'Hamilton 8" Rechargeable Table Fan HT-7092',
            'desc' => 'High quality Hamilton 8-inch rechargeable desk fan with emergency LED light, dual power options, and long-lasting backup.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 23,
            'name' => 'YiLFo Professional Cordless Hair Clipper & Trimmer Kit',
            'desc' => 'Professional cordless hair cutting and detail trimming grooming kit with guide combs, barber shears, and rechargeable battery.',
            'category_id' => 2,
            'image_url' => null,
        ],
        [
            'id' => 24,
            'name' => 'Pyle Vintage Classic Rotary Dial Telephone Set',
            'desc' => 'Classic retro rotary dial landline telephone in glossy black finish with coiled handset cord and authentic bell ringer.',
            'category_id' => 4,
            'image_url' => null,
        ],
        [
            'id' => 25,
            'name' => 'Panasonic 6L Digital Air Fryer with Viewing Window',
            'desc' => 'Crispy, juicy, healthy cooking with 6L large capacity, transparent viewing window, gentle steam technology, and 360-degree airflow.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 26,
            'name' => 'Portable Handheld Mini Fan with Digital Display',
            'desc' => 'Pocket handheld rechargeable mini fan with LED battery percentage display, folding head, and neck lanyard.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 27,
            'name' => 'Prestige Delight Electric Rice Cooker 1.8L',
            'desc' => 'Prestige Delight cyan blue electric rice cooker 1.8L with non-stick cooking bowl, keep-warm feature, and glass lid.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 45,
            'name' => 'Nova Rechargeable Table Fan with Emergency Light',
            'desc' => 'Nova multi-speed rechargeable table fan with 5 aerodynamic pink blades, emergency LED night light, and USB mobile phone charging output.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 53,
            'name' => 'JY-1880 Rechargeable Mini Desk Fan',
            'desc' => 'JY-1880 compact portable rechargeable desk fan with yellow spiral safety grill, two speed settings, and USB charging.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 55,
            'name' => 'LR-2018 Telescopic Foldable Rechargeable Fan',
            'desc' => 'Telescopic height-adjustable foldable desk fan LR-2018 with built-in LED night lamp and long-lasting rechargeable battery.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 56,
            'name' => 'Miyako Electric Curry Cooker 5.5L',
            'desc' => 'Miyako 5.5L multi-purpose electric curry cooker with glass lid, non-stick cooking pot, and automatic heat control.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 58,
            'name' => 'Miyako Pink Panther Mixer Grinder 750W',
            'desc' => 'Miyako Pink Panther 750W copper motor mixer grinder with stainless steel jars, pulse control, and overload protection.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 61,
            'name' => 'Joykaly YG-717 Mini Rechargeable LED Fan',
            'desc' => 'Joykaly YG-717 mini rechargeable folding desk fan with 2400mAh battery, 8-10 hour backup, and built-in night light.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 62,
            'name' => 'Star Track Multi-Function Air Fryer',
            'desc' => 'Star Track mechanical multi-function air fryer with dual rotary dials for temperature and timer control.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 63,
            'name' => 'Sonifer Electric Sandwich & Panini Grill Maker 750W',
            'desc' => 'Sonifer compact 750W non-stick electric sandwich and panini press grill with automatic thermostat and cool-touch handle.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 65,
            'name' => 'Chefman Electric Glass Kettle with Infuser 1.8L',
            'desc' => 'Chefman premium 1.8L borosilicate glass electric kettle with stainless steel tea infuser and auto-shutoff protection.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 66,
            'name' => 'Solar Powered Rechargeable Desk Fan with Solar Panel',
            'desc' => 'Solar powered rechargeable desk fan with external photovoltaic solar panel, dual LED bulbs, and USB output.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 67,
            'name' => 'V-Guard Electric Induction Cooktop 1800W',
            'desc' => 'V-Guard 1800W high-speed induction cooktop with 7 cooking power levels, auto-off timer, and overheat protection.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 68,
            'name' => 'Sensio Home 3-in-1 Hand Blender & Whisk',
            'desc' => 'Sensio Home stainless steel immersion stick blender with ergonomic grip, balloon whisk, and variable speed settings.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 69,
            'name' => 'Electric Octopus Head & Scalp Massager',
            'desc' => 'Hands-free octopus-claw electric vibration scalp massager for stress relief, headache soothing, and hair stimulation.',
            'category_id' => 2,
            'image_url' => null,
        ],
        [
            'id' => 71,
            'name' => 'Smart Mini Electric Multi Cooker with Digital Preset',
            'desc' => 'Compact digital electric multi cooker with carrying handle, preset cooking programs for rice, soup, porridge, and stew.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 72,
            'name' => 'Multi-Function Electric Hot Pot Cooker 1.5L',
            'desc' => 'Electric ramen and noodle hot pot with wooden anti-scald handle, non-stick inner coating, and dry-burn protection.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 73,
            'name' => 'Portable Handheld Mini Fan with Digital Display',
            'desc' => 'Compact pocket rechargeable handheld fan with LED battery percentage display, foldable stand, and lanyard.',
            'category_id' => 3,
            'image_url' => null,
        ],
        [
            'id' => 75,
            'name' => 'Noha Super Magic Blender & Mixer Grinder 1050W',
            'desc' => 'Noha Super Magic 1050W heavy-duty copper motor blender with 3 stainless steel jars, durable blades, and 1-year warranty.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 76,
            'name' => 'Haeger Stainless Steel Rice Cooker & Steamer 1.8L',
            'desc' => 'Haeger 1.8L stainless steel automatic electric rice cooker with food-grade steamer basket, tempered glass lid, and keep-warm function.',
            'category_id' => 1,
            'image_url' => null,
        ],
        [
            'id' => 77,
            'name' => 'Pyle Vintage Classic Rotary Dial Telephone Set',
            'desc' => 'Classic retro rotary dial landline telephone in glossy black finish with coiled handset cord and authentic bell ringer.',
            'category_id' => 4,
            'image_url' => null,
        ],
        [
            'id' => 122,
            'name' => 'Miyako 3-in-1 Electric Blender & Grinder',
            'desc' => 'Miyako 3-in-1 multi-purpose electric blender with food grade blending jug, wet and dry grinder jars, and motor safety protection.',
            'category_id' => 1,
            'image_url' => null,
        ],
    ];

    $updatedCount = 0;
    foreach ($updates as $u) {
        $cat = in_array($u['category_id'], $validCategories) ? $u['category_id'] : null;
        
        if (!empty($u['image_url'])) {
            if ($cat !== null) {
                $stmt = $db->prepare("UPDATE products SET product_name = :name, description = :desc, category_id = :cat, image_url = :img WHERE product_id = :id");
                $stmt->execute([':name' => $u['name'], ':desc' => $u['desc'], ':cat' => $cat, ':img' => $u['image_url'], ':id' => $u['id']]);
            } else {
                $stmt = $db->prepare("UPDATE products SET product_name = :name, description = :desc, image_url = :img WHERE product_id = :id");
                $stmt->execute([':name' => $u['name'], ':desc' => $u['desc'], ':img' => $u['image_url'], ':id' => $u['id']]);
            }
        } else {
            if ($cat !== null) {
                $stmt = $db->prepare("UPDATE products SET product_name = :name, description = :desc, category_id = :cat WHERE product_id = :id");
                $stmt->execute([':name' => $u['name'], ':desc' => $u['desc'], ':cat' => $cat, ':id' => $u['id']]);
            } else {
                $stmt = $db->prepare("UPDATE products SET product_name = :name, description = :desc WHERE product_id = :id");
                $stmt->execute([':name' => $u['name'], ':desc' => $u['desc'], ':id' => $u['id']]);
            }
        }
        $updatedCount++;
    }

    echo json_encode([
        'success' => true,
        'message' => "Successfully updated $updatedCount products in the database.",
        'count' => $updatedCount,
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
    ], JSON_PRETTY_PRINT);
}
