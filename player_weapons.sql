CREATE TABLE IF NOT EXISTS `player_weapons` (
    `id` int NOT NULL AUTO_INCREMENT,
    `serial` varchar(16) NOT NULL,
    `citizenid` varchar(9) NOT NULL,
    `components` varchar(4096) NOT NULL DEFAULT '{}',
    `components_before` varchar(4096) NOT NULL DEFAULT '{}',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sample Data
INSERT INTO `player_weapons` (`id`, `serial`, `components`) VALUES
(1, 'BM123456','[{"GRIP":"COMPONENT_PISTOL_MAUSER_GRIP_BURLED","SIGHT":"COMPONENT_PISTOL_MAUSER_SIGHT_WIDE"}]')
