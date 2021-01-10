--
-- Structure de la table `points`
--

CREATE TABLE `points` (
  `id` int(11) NOT NULL,
  `steamid` varchar(64) NOT NULL,
  `points` int(11) NOT NULL,
  `hud` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Index pour la table `points`
--
ALTER TABLE `points`
  ADD PRIMARY KEY (`id`);