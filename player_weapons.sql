CREATE TABLE IF NOT EXISTS `player_weapons` (
    `id` int NOT NULL AUTO_INCREMENT,
    `serial` varchar(16) NOT NULL,
    `citizenid` varchar(9) NOT NULL,
    `components` varchar(4096) NOT NULL DEFAULT '{}',
    `components_before` varchar(4096) NOT NULL DEFAULT '{}',
    `ammo` int(3) NOT NULL DEFAULT 0,
    `ammo_express` int(3) NOT NULL DEFAULT 0,
    `ammo_express_explosive` int(3) NOT NULL DEFAULT 0,
    `ammo_high_velocity` int(3) NOT NULL DEFAULT 0,
    `ammo_split_point` int(3) NOT NULL DEFAULT 0,
    `ammo_buckshot_incendiary` int(3) NOT NULL DEFAULT 0,
    `ammo_slug` int(3) NOT NULL DEFAULT 0,
    `ammo_slug_explosive` int(3) NOT NULL DEFAULT 0,
    `ammo_tranquilizer` int(3) NOT NULL DEFAULT 0,
    `ammo_fire` int(3) NOT NULL DEFAULT 0,
    `ammo_poison` int(3) NOT NULL DEFAULT 0,
    `ammo_dynamite` int(3) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sample Data
INSERT INTO `player_weapons` (`id`, `serial`, `components`) VALUES
(1, 'BM123456','[{"GRIP":"COMPONENT_PISTOL_MAUSER_GRIP_BURLED","SIGHT":"COMPONENT_PISTOL_MAUSER_SIGHT_WIDE"}]')
