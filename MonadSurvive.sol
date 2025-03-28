// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MonadSurvive {
    // Reentrancy Guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Enums for flexible pool and bet rule types
    enum PoolRuleType { Standard, WithMaxBet }
    enum BetRuleType { 
        None,
        FirstThreeInOrder,      // İlk 3'ü sıralı tahmin
        LastFiveAnyOrder,       // Son 5'ten herhangi 3'ü
        MostBettedThree,       // En çok bahis alan 3 kişi
        FirstHourEliminated,    // İlk saatte elenenler
        GroupElimination,       // Grup eleme tahmini
        CombinationBet,        // Kombinasyon bahis
        TimeBasedElimination,   // Zaman bazlı eleme
        StatisticsBased,       // İstatistik bazlı tahmin
        TenthEliminated,       // Onuncu elenen tahmin
        LastN                  // Son N oyuncu tahmin
    }
    
    // Pool structure
    struct Pool {
        uint256 id;
        uint256 startTime;
        uint256 entranceFee;          // Participation fee (in wei)
        uint256 maxPlayers;           // Maximum number of players allowed
        uint256 eliminationInterval;  // Elimination period (in seconds)
        uint256 eliminationCount;     // Number of players eliminated per round
        uint256 winnerCount;          // Number of players remaining that will receive rewards
        bool active;
        address[] players;            // Array of active players
        PoolRuleType poolRule;        // Pool rule type
        BetRuleType betRule;          // Bet rule type
        uint256 betTarget;            // Target value for bet rule (e.g., 10 for 10th eliminated, 3 for last 3, etc.)
    }
    
    // Basic bet structure
    struct Bet {
        address player;
        uint256 amount;
        address guess;  // Guessed address (for instance, the 10th eliminated or a candidate among the remaining players)
    }
    
    struct BetType {
        string name;
        string description;
        uint256 minPlayers;
        uint256 rewardMultiplier;
        bool requiresOrder;      // Sıralı tahmin gerekiyor mu?
        bool isGroupBet;        // Grup bahsi mi?
        bool isTimeBased;       // Zaman bazlı mı?
        uint256 timeLimit;      // Varsa zaman limiti
    }
    
    struct AdvancedBetConfig {
        string betName;
        string description;
        uint256 minPlayers;
        uint256 rewardMultiplier;
        uint256 timeLimit;
        bool requiresSequence;
        bool isTeamBased;
        bool allowsMultipleGuesses;
    }

    // Yeni yapılar ekleyelim
    struct BetTypeConfig {
        string name;             // Bet tipi adı
        string description;      // Açıklama
        bool isActive;          // Aktif/Pasif durumu
        uint256 multiplier;     // Ödül çarpanı (örn: 200 = 2x)
        uint256 minPlayers;     // Minimum oyuncu sayısı
        uint256 maxWinners;     // Maximum kazanan sayısı
        bool requiresOrder;      // Sıralı tahmin gerekiyor mu?
        bool allowsMultiple;    // Çoklu tahmin yapılabilir mi?
        uint256 timeLimit;      // Zaman limiti
    }
    
    struct TimeVote {
        uint256 fast;    // 30 dakika oyları
        uint256 normal;  // 1 saat oyları
        uint256 slow;    // 2 saat oyları
    }
    
    // Havuz rule'larını temsil eden bitwise flags
    uint256 constant FEATURE_CHAIN_ELIMINATION = 1;      // Zincir eleme
    uint256 constant FEATURE_LAST_SURVIVOR = 2;         // Son kalanlar avantajı
    uint256 constant FEATURE_CRITICAL_ROUNDS = 4;       // Kritik turlar
    uint256 constant FEATURE_LEVEL_SYSTEM = 8;         // Seviye sistemi
    uint256 constant FEATURE_REVIVAL_POOL = 16;        // Geri dönüş havuzu
    uint256 constant FEATURE_DYNAMIC_TIMING = 32;      // Dinamik zamanlama
    uint256 constant FEATURE_RISK_LEVELS = 64;         // Risk seviyeleri
    uint256 constant FEATURE_POINT_SYSTEM = 128;       // Puan sistemi
    uint256 constant FEATURE_SUDDEN_DEATH = 256;       // Son 5 oyuncu modu
    uint256 constant FEATURE_RESCUE_TICKET = 512;      // Kurtulma bileti
    uint256 constant FEATURE_HEALING_TICKET = 1024;    // İyileşme bileti
    uint256 constant FEATURE_DOUBLE_ELIMINATION = 2048; // Çift eleme

    // Havuz özellikleri için yeni struct
    struct PoolFeatures {
        uint256 activeFeatures;           // Aktif özellikler
        uint256 lastSurvivorThreshold;    // Son kalanlar için eşik değeri
        mapping(address => uint256) riskLevel;      // Oyuncu risk seviyeleri (1=Safe, 2=Risky, 3=Ultra)
        mapping(address => uint256) points;         // Oyuncu puanları
        mapping(address => uint256) immunityCount;  // Muafiyet sayısı
        mapping(address => address) chainTarget;     // Hedef seçimleri
        uint256[] criticalRounds;                   // Kritik turlar
        uint256 currentRound;                       // Mevcut tur
        mapping(address => uint256) playerLevel;    // Oyuncu seviyeleri (1-4)
        mapping(uint256 => uint256) levelMultipliers; // Seviye çarpanları
        address[] revivalPool;                      // Geri dönüş havuzu
        mapping(address => bool) isAtRisk;          // Risk durumu
        mapping(address => uint256) timeVotes;      // Zaman oylamaları
        uint256 nextEliminationTime;               // Sonraki eleme zamanı
        mapping(address => bool) hasImmunity;       // Oyuncu muafiyet durumu
        mapping(address => uint256) immunityExpiry; // Muafiyet süresi
        uint256 rewardMultiplier;                   // Ödül çarpanı
        mapping(address => bool) hasBonusReward;    // Bonus ödül durumu
        mapping(address => uint256) bonusAmount;    // Bonus ödül miktarı
        bool isSuddenDeathActive;                   // Son aşama aktif mi
        uint256 rescueTicketPrice;                  // Kurtulma bileti fiyatı
        uint256 healingTicketPrice;                 // İyileşme bileti fiyatı
        mapping(address => bool) hasRescueTicket;   // Kurtulma bileti sahipliği
        mapping(address => bool) hasHealingTicket;  // İyileşme bileti sahipliği
        mapping(address => bool) isWounded;         // Yaralı durumu
    }

    address public owner;
    uint256 public poolCounter;
    mapping(uint256 => Pool) public pools;
    
    // Funds collected from pool participations
    mapping(uint256 => uint256) public poolFunds;
    // Funds collected from bets
    mapping(uint256 => uint256) public betFunds;
    
    // Bets per pool
    mapping(uint256 => Bet[]) public bets;
    // List of eliminated players per pool
    mapping(uint256 => address[]) public eliminatedPlayers;
    // For MaxBetVote: mapping of candidate address to number of votes per pool
    mapping(uint256 => mapping(address => uint256)) public betVotes;
    // Rewards mapping: poolId => (player => reward amount)
    mapping(uint256 => mapping(address => uint256)) public rewards;
    
    mapping(uint256 => AdvancedBetConfig) public betConfigs;

    // Havuz-bet tipi ilişkisi için yeni mapping'ler
    mapping(uint256 => mapping(uint256 => bool)) public poolActiveBetTypes;    // poolId => betTypeId => isActive
    mapping(uint256 => uint256[]) public poolBetTypes;                         // poolId => betType[]
    mapping(uint256 => BetTypeConfig) public betTypeConfigs;                   // betTypeId => config
    uint256 public betTypeCounter;

    // Havuz özellikleri için yeni state değişkenleri
    mapping(uint256 => PoolFeatures) public poolFeatures;
    uint256 public ticketFunds;      // Bilet satışlarından toplanan fonlar
    
    // Platform fee percentage (example: 10%) and collected platform fees
    uint256 public PLATFORM_FEE_PERCENT = 10;
    uint256 public collectedPlatformFees;

    mapping(address => uint256) public ticketExpiry;
    uint256 public constant TICKET_VALIDITY = 24 hours;
    
    // Events for logging important actions
    event PoolCreated(
        uint256 indexed poolId,
        uint256 startTime,
        uint256 entranceFee,
        uint256 maxPlayers,
        PoolRuleType poolRule,
        BetRuleType betRule,
        uint256 betTarget
    );
    event JoinedPool(uint256 indexed poolId, address indexed player);
    event BetPlaced(uint256 indexed poolId, address indexed player, uint256 amount, address guess);
    event Eliminated(uint256 indexed poolId, address[] eliminatedPlayers, uint256 eliminationRound);
    event WinnerSelected(uint256 indexed poolId, address[] winners);
    event BetWinnersSelected(uint256 indexed poolId, address[] betWinners);
    event RewardClaimed(uint256 indexed poolId, address indexed player, uint256 amount);
    event BetTypeCreated(uint256 indexed betTypeId, string name, uint256 multiplier);
    event BetTypeAddedToPool(uint256 indexed poolId, uint256 indexed betTypeId);
    event BetTypeRemovedFromPool(uint256 indexed poolId, uint256 indexed betTypeId);
    event BetMultiplierUpdated(uint256 indexed betTypeId, uint256 newMultiplier);
    event TicketPurchased(uint256 indexed poolId, address indexed player, bool isRescueTicket);
    event TicketUsed(uint256 indexed poolId, address indexed player, bool isRescueTicket);
    event PlayerWounded(uint256 indexed poolId, address indexed player);
    event PlayerHealed(uint256 indexed poolId, address indexed player);
    event ImmunityGranted(uint256 indexed poolId, address indexed player, uint256 duration);
    event RewardMultiplierIncreased(uint256 indexed poolId, uint256 amount);
    event SurvivorBonusAwarded(uint256 indexed poolId, address indexed player, uint256 bonus);
    event SuddenDeathActivated(uint256 indexed poolId);
    event BonusRewardMarked(uint256 indexed poolId, address indexed player);
    event PlayerTargeted(uint256 indexed poolId, address indexed targeter, address indexed target);
    event RiskLevelChanged(uint256 indexed poolId, address indexed player, uint256 level);
    event CriticalRoundStarted(uint256 indexed poolId, uint256 roundNumber);
    event PlayerLeveledUp(uint256 indexed poolId, address indexed player, uint256 newLevel);
    event EliminationOccurred(uint256 indexed poolId, address indexed player);
    event RoundAdvanced(uint256 indexed poolId, uint256 roundNumber);
    event ImmunityExpired(uint256 indexed poolId, address indexed player);
    event TimeVoteSubmitted(uint256 indexed poolId, address indexed player, uint256 choice);
    event LevelMultiplierSet(uint256 indexed poolId, uint256 level, uint256 multiplier);
    event BetWon(uint256 indexed poolId, address indexed better, uint256 amount, address targetGuess);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }
    
    /// @notice Creates a new pool with flexible parameters.
    /// @param entranceFee Participation fee (in wei)
    /// @param maxPlayers Maximum number of players allowed in the pool
    /// @param eliminationInterval Time interval for each elimination round (in seconds)
    /// @param eliminationCount Number of players eliminated each round
    /// @param winnerCount Number of players remaining that will receive rewards
    /// @param poolFeaturesFlag Bitwise flags for pool features
    /// @param rescueTicketPrice Price of rescue tickets
    /// @param healingTicketPrice Price of healing tickets
    /// @param accelerationRate Acceleration rate for elimination interval
    /// @param criticalMultiplier Multiplier for critical rounds
    function createPool(
        uint256 entranceFee,
        uint256 maxPlayers,
        uint256 eliminationInterval,
        uint256 eliminationCount,
        uint256 winnerCount,
        uint256 poolFeaturesFlag,
        uint256 rescueTicketPrice,
        uint256 healingTicketPrice,
        uint256 accelerationRate,
        uint256 criticalMultiplier
    ) public onlyOwner {
        require(rescueTicketPrice > 0, "Invalid rescue ticket price");
        require(healingTicketPrice > 0, "Invalid healing ticket price");
        require(accelerationRate >= 100 && accelerationRate <= 500, "Invalid acceleration rate");
        require(criticalMultiplier > 100 && criticalMultiplier <= 500, "Invalid critical multiplier");
        
        // Temel validasyonlar
        require(entranceFee > 0, "Entrance fee must be > 0");
        require(maxPlayers >= 5, "Min 5 players required");
        require(eliminationInterval >= 300, "Min interval 5 minutes");
        require(eliminationCount > 0 && eliminationCount < maxPlayers, "Invalid elimination count");
        require(winnerCount > 0 && winnerCount < maxPlayers, "Invalid winner count");
        require(maxPlayers > winnerCount, "Max players must be > winner count");
        
        // Özel özellik validasyonları
        if(poolFeaturesFlag & FEATURE_CHAIN_ELIMINATION != 0) {
            require(eliminationCount == 1, "Chain elimination requires single eliminations");
        }
        
        if(poolFeaturesFlag & FEATURE_CRITICAL_ROUNDS != 0) {
            require(criticalMultiplier > 100, "Invalid critical multiplier");
        }

        poolCounter++;
        Pool storage newPool = pools[poolCounter];
        newPool.id = poolCounter;
        newPool.startTime = block.timestamp;
        newPool.entranceFee = entranceFee;
        newPool.maxPlayers = maxPlayers;
        newPool.eliminationInterval = eliminationInterval;
        newPool.eliminationCount = eliminationCount;
        newPool.winnerCount = winnerCount;
        newPool.active = true;

        // PoolFeatures başlatma
        PoolFeatures storage features = poolFeatures[poolCounter];
        features.activeFeatures = poolFeaturesFlag;
        features.rewardMultiplier = 1;
        features.isSuddenDeathActive = false;
        features.rescueTicketPrice = rescueTicketPrice;
        features.healingTicketPrice = healingTicketPrice;
        features.lastSurvivorThreshold = 5; // Varsayılan değer
        features.nextEliminationTime = block.timestamp + (eliminationInterval / accelerationRate);

        emit PoolCreated(
            poolCounter, 
            newPool.startTime, 
            entranceFee, 
            maxPlayers, 
            PoolRuleType.Standard, 
            BetRuleType.None, 
            0
        );
    }

    /// @notice Creates an advanced pool with additional parameters.
    /// @param entranceFee Participation fee (in wei)
    /// @param maxPlayers Maximum number of players allowed in the pool
    /// @param eliminationInterval Time interval for each elimination round (in seconds)
    /// @param eliminationCount Number of players eliminated each round
    /// @param winnerCount Number of players remaining that will receive rewards
    /// @param featuresFlag Bitwise flags for pool features
    /// @param criticalRounds Array of critical rounds
    /// @param lastSurvivorThreshold Threshold for last survivor
    /// @param levelMultipliers Array of level multipliers
    /// @return poolId ID of the created pool
    function createAdvancedPool(
        uint256 entranceFee,
        uint256 maxPlayers,
        uint256 eliminationInterval,
        uint256 eliminationCount,
        uint256 winnerCount,
        uint256 featuresFlag,
        uint256[] memory criticalRounds,
        uint256 lastSurvivorThreshold,
        uint256[] memory levelMultipliers
    ) public onlyOwner returns (uint256) {
        poolCounter++;
        Pool storage newPool = pools[poolCounter];
        newPool.id = poolCounter;
        newPool.startTime = block.timestamp;
        newPool.entranceFee = entranceFee;
        newPool.maxPlayers = maxPlayers;
        newPool.eliminationInterval = eliminationInterval;
        newPool.eliminationCount = eliminationCount;
        newPool.winnerCount = winnerCount;
        newPool.active = true;

        // PoolFeatures başlatma
        PoolFeatures storage pf = poolFeatures[poolCounter];
        pf.activeFeatures = featuresFlag;
        pf.rewardMultiplier = 1;
        pf.isSuddenDeathActive = false;
        pf.lastSurvivorThreshold = lastSurvivorThreshold;
        
        // Kritik turları ayarla
        for(uint256 i = 0; i < criticalRounds.length; i++) {
            pf.criticalRounds.push(criticalRounds[i]);
        }

        // Level multipliers'ı sakla
        for(uint256 i = 0; i < levelMultipliers.length && i < 4; i++) {
            pf.levelMultipliers[i+1] = levelMultipliers[i];
        }

        emit PoolCreated(poolCounter, newPool.startTime, entranceFee, maxPlayers, PoolRuleType.Standard, BetRuleType.None, 0);
        return poolCounter;
    }
    
    /// @notice Allows a user to join a pool.
    /// @param poolId ID of the pool to join.
    function joinPool(uint256 poolId) external payable {
        require(pools[poolId].active, "Pool is not active");
        require(msg.value == pools[poolId].entranceFee, "Incorrect participation fee sent");
        require(pools[poolId].players.length < pools[poolId].maxPlayers, "Pool is full");
        
        // Başka kontroller
        require(!isEliminated(poolId, msg.sender), "Player already eliminated");
        require(!poolFeatures[poolId].isWounded[msg.sender], "Player is wounded");
        
        // Doğrudan mapping'e erişim
        pools[poolId].players.push(msg.sender);
        
        // Havuz doluysa başlama zamanını güncelle
        if(pools[poolId].players.length == pools[poolId].maxPlayers) {
            pools[poolId].startTime = block.timestamp;
        }
        
        // Havuz fonlarını güncelle
        poolFunds[poolId] += msg.value;
        
        // Olay tetikle
        emit JoinedPool(poolId, msg.sender);
    }
    
    /// @notice Allows a user to place a bet. The guessed address must comply with the bet rule.
    /// @param poolId ID of the pool for which the bet is placed.
    /// @param guess The address being guessed.
    function placeBet(uint256 poolId, address guess) external payable {
        Pool storage pool = pools[poolId];
        require(pool.active, "Pool is not active");
        require(msg.value > 0, "Bet amount must be greater than zero");
        
        // Bahis tipi validasyonu ekle
        validateBetType(poolId, pool.betRule, guess);
        
        bets[poolId].push(Bet({
            player: msg.sender,
            amount: msg.value,
            guess: guess
        }));
        betFunds[poolId] += msg.value;
        
        emit BetPlaced(poolId, msg.sender, msg.value, guess);
    }

    // Bahis validasyon fonksiyonu ekle
    function validateBetType(uint256 poolId, BetRuleType betRule, address guess) internal view {
        Pool storage pool = pools[poolId];
        
        if (betRule == BetRuleType.FirstThreeInOrder) {
            require(eliminatedPlayers[poolId].length < 3, "First three already eliminated");
        } 
        else if (betRule == BetRuleType.LastFiveAnyOrder) {
            require(pool.players.length <= 5, "More than 5 players remaining");
        }
        else if (betRule == BetRuleType.GroupElimination) {
            require(isInArray(pool.players, guess), "Invalid target for group elimination");
        }
    }
    
    /// @notice Executes an elimination round. The owner calls this function after the elimination interval.
    /// @param poolId ID of the pool for which elimination is performed.
    function eliminate(uint256 poolId) public onlyOwner {
        // Pool değişkenini aktif olarak kullanalım
        Pool storage pool = pools[poolId]; 
        PoolFeatures storage features = poolFeatures[poolId];

        // Risk bazlı eleme şansı hesaplama
        address[] memory eligiblePlayers = getEligiblePlayers(poolId);
        uint256[] memory chances = calculateEliminationChances(poolId, eligiblePlayers);

        // Weighted random seçim
        address playerToEliminate = selectWeightedRandom(poolId, eligiblePlayers, chances);

        // Zincir reaksiyon
        if(features.activeFeatures & FEATURE_CHAIN_ELIMINATION != 0) {
            markAdjacentPlayersAtRisk(poolId, playerToEliminate);
        }

        // Pool değişkenini aktif kullan
        if (pool.players.length <= 5) {
            activateSuddenDeath(poolId);
        }
        
        // Eleme işlemi
        processElimination(poolId, playerToEliminate);
        
        // Bahis kazananlarını işleme
        processBetWinners(poolId, playerToEliminate);
        
        // Tur kontrolü
        if (isCriticalRound(poolId)) {
            pool.eliminationCount *= 2;
        }
        
        // Havuz durumunu güncelle
        updatePoolState(poolId);
    }
    
    /// @dev Calculates and assigns rewards from both pool funds and bet funds.
    function distributeRewards(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        pool.active = false;
        
        // ----- POOL REWARD -----
        uint256 totalPoolFunds = poolFunds[poolId];
        uint256 platformFee = (totalPoolFunds * PLATFORM_FEE_PERCENT) / 100;
        collectedPlatformFees += platformFee;
        uint256 rewardPool = totalPoolFunds - platformFee;
        uint256 poolShare = rewardPool / pool.players.length;
        
        for (uint256 i = 0; i < pool.players.length; i++) {
            rewards[poolId][pool.players[i]] += poolShare;
        }
        emit WinnerSelected(poolId, pool.players);
        
        // ----- BET REWARD -----
        processBetRewards(poolId);
    }
    
    /// @dev Processes bet rewards according to the pool's bet rule.
    function processBetRewards(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        uint256 totalBetFunds = betFunds[poolId];
        
        if(totalBetFunds == 0) return;
        
        if (pool.betRule == BetRuleType.FirstThreeInOrder) {
            processFirstThreeInOrderBets(poolId);
        }
        else if (pool.betRule == BetRuleType.LastFiveAnyOrder) {
            processLastFiveAnyOrderBets(poolId);
        }
        else if (pool.betRule == BetRuleType.GroupElimination) {
            processGroupEliminationBets(poolId);
        }
        else if (pool.betRule == BetRuleType.FirstHourEliminated) {
            processFirstHourBets(poolId);
        }
        else if (pool.betRule == BetRuleType.MostBettedThree) {
            processMostBettedBets(poolId);
        }
        else if (pool.betRule == BetRuleType.CombinationBet) {
            processCombinationBets(poolId);
        }
        else if (pool.betRule == BetRuleType.TimeBasedElimination) {
            processTimeBasedBets(poolId);
        }
        else if (pool.betRule == BetRuleType.StatisticsBased) {
            processStatisticsBets(poolId);
        }
    }

    // Yeni bet tipi ödül fonksiyonları
    function processFirstThreeInOrderBets(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        address[] memory firstThree = getFirstThreeEliminated(poolId);
        
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            Bet storage bet = bets[poolId][i];
            if (checkFirstThreeMatch(bet.guess, firstThree)) {
                uint256 reward = calculateBetReward(poolId, bet.amount, 3); // 3x ödül
                rewards[poolId][bet.player] += reward;
                emit BetWon(poolId, bet.player, reward, bet.guess);
            }
        }
    }

    function processLastFiveAnyOrderBets(uint256 poolId) internal {
        // Son 5 oyuncu için bahis hesaplaması
    }

    function processGroupEliminationBets(uint256 poolId) internal {
        // Grup eleme bahisleri için hesaplama
    }

    function processFirstHourBets(uint256 poolId) internal {
        // İlk saatte elenenler için bahis hesaplaması
    }

    function processMostBettedBets(uint256 poolId) internal {
        // En çok bahis alan 3 kişi için bahis hesaplaması
    }

    function processCombinationBets(uint256 poolId) internal {
        // Kombinasyon bahisleri için hesaplama
    }

    function processTimeBasedBets(uint256 poolId) internal {
        // Zaman bazlı eleme bahisleri için hesaplama
    }

    function processStatisticsBets(uint256 poolId) internal {
        // İstatistik bazlı bahisler için hesaplama
    }
    
    /// @notice Allows players to claim their rewards.
    /// @param poolId ID of the pool from which to claim rewards.
    function claimReward(uint256 poolId) external nonReentrant {
        uint256 rewardAmount = rewards[poolId][msg.sender];
        require(rewardAmount > 0, "No reward available to claim");
        rewards[poolId][msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "Reward transfer failed");
        emit RewardClaimed(poolId, msg.sender, rewardAmount);
    }
    
    /// @notice Allows the owner to withdraw collected platform fees.
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = collectedPlatformFees + ticketFunds;
        require(amount > 0, "No fees to withdraw");
        collectedPlatformFees = 0;
        ticketFunds = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }

    /// @notice Havuzdaki oyuncuları döndürür
    /// @param poolId Havuz ID'si
    /// @return Havuzdaki oyuncuların adresleri
    function getPoolPlayers(uint256 poolId) public view returns (address[] memory) {
        return pools[poolId].players;
    }
    
    // Addresses için isInArray
    function isInArray(address[] memory array, address addr) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == addr) return true;
        }
        return false;
    }

    // uint256 için isInArray
    function isInArray(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) return true;
        }
        return false;
    }
    
    // validateBet fonksiyonunu düzelt - Doğrudan mapping kullanımı
    function validateBet(uint256 poolId, BetRuleType betRule) internal view {
        require(pools[poolId].active, "Pool not active");
        require(pools[poolId].maxPlayers > 0, "Invalid pool configuration");
        require(pools[poolId].entranceFee > 0, "Invalid entrance fee");
        require(pools[poolId].eliminationInterval > 0, "Invalid elimination interval");
        
        if(betRule == BetRuleType.TenthEliminated) {
            require(pools[poolId].maxPlayers >= 10, "Pool capacity not suitable");
            require(pools[poolId].eliminationCount > 0, "Invalid elimination count");
        } else if(betRule == BetRuleType.LastN) {
            require(pools[poolId].maxPlayers > pools[poolId].winnerCount, "Invalid capacity");
            require(pools[poolId].players.length >= pools[poolId].winnerCount, "Not enough players");
        }
    }

    // validateTenthElimination fonksiyonu
    function validateTenthElimination(uint256 poolId) internal view {
        require(pools[poolId].maxPlayers >= 10, "Pool capacity not suitable");
        require(pools[poolId].eliminationCount > 0, "Invalid elimination count");
    }

    // validateLastN fonksiyonu
    function validateLastN(uint256 poolId) internal view {
        require(pools[poolId].maxPlayers > pools[poolId].winnerCount, "Invalid capacity");
        require(pools[poolId].players.length >= pools[poolId].winnerCount, "Not enough players");
    }

    // validateMaxBet fonksiyonu
    function validateMaxBet(uint256 poolId) internal view {
        require(pools[poolId].betTarget > 0, "Invalid bet target");
        require(pools[poolId].players.length > 0, "No players in pool");
    }

    // Yardımcı fonksiyonları view olarak değiştir
    function validateTenthElimination(Pool storage pool) internal view {
        require(pool.maxPlayers >= 10, "Pool capacity not suitable");
        require(pool.eliminationCount > 0, "Invalid elimination count");
    }

    function validateLastN(Pool storage pool) internal view {
        require(pool.maxPlayers > pool.winnerCount, "Invalid capacity");
        require(pool.players.length >= pool.winnerCount, "Not enough players");
        require(block.timestamp >= pool.startTime, "Pool not started");
    }

    function validateMaxBet(Pool storage pool) internal view {
        require(pool.betTarget > 0, "Invalid bet target");
        require(pool.players.length > 0, "No players in pool");
    }

    // calculateBetReward fonksiyonunu düzelt
    function calculateBetReward(
        uint256 poolId,
        uint256 betAmount,
        uint256 multiplier
    ) internal view returns (uint256) {
        // Doğrudan mapping kullanımı
        uint256 baseReward = betAmount * multiplier;
        uint256 finalReward = baseReward * poolFeatures[poolId].rewardMultiplier / 100;
        
        if (poolFeatures[poolId].activeFeatures & FEATURE_CRITICAL_ROUNDS != 0) {
            if(isInArray(poolFeatures[poolId].criticalRounds, poolFeatures[poolId].currentRound)) {
                finalReward *= 2;
                if(poolFeatures[poolId].playerLevel[msg.sender] > 2) {
                    finalReward += poolFeatures[poolId].playerLevel[msg.sender] * 50;
                }
            }
        }
        
        if (poolFeatures[poolId].playerLevel[msg.sender] > 1) {
            finalReward += (finalReward * poolFeatures[poolId].playerLevel[msg.sender] * 10) / 100;
        }
        
        if (poolFeatures[poolId].riskLevel[msg.sender] > 1) {
            finalReward += (finalReward * poolFeatures[poolId].riskLevel[msg.sender] * 5) / 100;
        }
        
        return finalReward;
    }

    // Bahis tipi ekleme fonksiyonu
   function addBetTypeConfig(
    string memory _name,           // Eksik parametre eklendi
    string memory _description,    // Eksik parametre eklendi
    uint256 _multiplier,          // Eksik parametre eklendi
    uint256 _minPlayers,          // Eksik parametre eklendi
    bool _isTimeBased,            // Eksik parametre eklendi
    uint256 _timeLimit
) external onlyOwner {
    betTypeCounter++;
    betTypeConfigs[betTypeCounter] = BetTypeConfig({
        name: _name,
        description: _description,
        isActive: true,
        multiplier: _multiplier,
        minPlayers: _minPlayers,
        maxWinners: 1,
        requiresOrder: _isTimeBased,
        allowsMultiple: false,
        timeLimit: _timeLimit
    });
    
    emit BetTypeCreated(betTypeCounter, _name, _multiplier);
}
    
    function setupAdvancedBet(
        uint256 betTypeId,
        string memory name,
        string memory description,
        uint256 minPlayers,
        uint256 rewardMultiplier,
        uint256 timeLimit,
        bool requiresSequence,
        bool isTeamBased,
        bool allowsMultipleGuesses
    ) external onlyOwner {
        betConfigs[betTypeId] = AdvancedBetConfig({
            betName: name,
            description: description,
            minPlayers: minPlayers,
            rewardMultiplier: rewardMultiplier,
            timeLimit: timeLimit,
            requiresSequence: requiresSequence,
            isTeamBased: isTeamBased,
            allowsMultipleGuesses: allowsMultipleGuesses
        });
    }

    // Yeni fonksiyonlar ekleyelim
    function createBetType(
        string memory _name,
        string memory _description,
        uint256 _multiplier,
        uint256 _minPlayers,
        uint256 _maxWinners,
        bool _requiresOrder,
        bool _allowsMultiple
    ) public onlyOwner returns (uint256) {
        betTypeCounter++;
        
        betTypeConfigs[betTypeCounter] = BetTypeConfig({
            name: _name,
            description: _description,
            isActive: true,
            multiplier: _multiplier,
            minPlayers: _minPlayers,
            maxWinners: _maxWinners,
            requiresOrder: _requiresOrder,
            allowsMultiple: _allowsMultiple,
            timeLimit: 0
        });

        emit BetTypeCreated(betTypeCounter, _name, _multiplier);
        return betTypeCounter;
    }

    // Havuza bet tipi ekleme
    function addBetTypeToPool(
        uint256 _poolId, 
        uint256 _betTypeId
    ) public onlyOwner {
        require(pools[_poolId].active, "Pool not active");
        require(betTypeConfigs[_betTypeId].isActive, "Bet type not active");
        require(!poolActiveBetTypes[_poolId][_betTypeId], "Bet type already added");

        poolActiveBetTypes[_poolId][_betTypeId] = true;
        poolBetTypes[_poolId].push(_betTypeId);

        emit BetTypeAddedToPool(_poolId, _betTypeId);
    }

    // Havuzdan bet tipi çıkarma
    function removeBetTypeFromPool(
        uint256 _poolId, 
        uint256 _betTypeId
    ) external onlyOwner {
        require(pools[_poolId].active, "Pool not active");
        require(poolActiveBetTypes[_poolId][_betTypeId], "Bet type not in pool");

        poolActiveBetTypes[_poolId][_betTypeId] = false;
        
        emit BetTypeRemovedFromPool(_poolId, _betTypeId);
    }

    // Bet tipi çarpanını güncelleme
    function updateBetMultiplier(
        uint256 _betTypeId, 
        uint256 _newMultiplier
    ) external onlyOwner {
        require(betTypeConfigs[_betTypeId].isActive, "Bet type not active");
        betTypeConfigs[_betTypeId].multiplier = _newMultiplier;
        
        emit BetMultiplierUpdated(_betTypeId, _newMultiplier);
    }

    // Havuzun aktif bet tiplerini görüntüleme
    function getPoolActiveBetTypes(
        uint256 _poolId
    ) external view returns (uint256[] memory activeBetTypes) {
        uint256[] memory allTypes = poolBetTypes[_poolId];
        uint256 activeCount = 0;
        
        // Önce aktif bet sayısını bul
        for(uint256 i = 0; i < allTypes.length; i++) {
            if(poolActiveBetTypes[_poolId][allTypes[i]]) {
                activeCount++;
            }
        }
        
        // Aktif betleri diziye ekle
        activeBetTypes = new uint256[](activeCount);
        uint256 index = 0;
        for(uint256 i = 0; i < allTypes.length; i++) {
            if(poolActiveBetTypes[_poolId][allTypes[i]]) {
                activeBetTypes[index] = allTypes[i];
                index++;
            }
        }
        
        return activeBetTypes;
    }

    // Bilet satın alma fonksiyonları
    function purchaseRescueTicket(uint256 poolId) external payable {
        PoolFeatures storage features = poolFeatures[poolId];
        require(features.activeFeatures & FEATURE_RESCUE_TICKET != 0, "Rescue tickets not enabled");
        require(msg.value == features.rescueTicketPrice, "Incorrect ticket price");
        require(!features.hasRescueTicket[msg.sender], "Already has rescue ticket");

        features.hasRescueTicket[msg.sender] = true;
        ticketFunds += msg.value;
        emit TicketPurchased(poolId, msg.sender, true);
    }

    function purchaseHealingTicket(uint256 poolId) external payable {
        PoolFeatures storage features = poolFeatures[poolId];
        require(features.activeFeatures & FEATURE_HEALING_TICKET != 0, "Healing tickets not enabled");
        require(msg.value == features.healingTicketPrice, "Incorrect ticket price");
        require(features.isWounded[msg.sender], "Player not wounded");

        features.hasHealingTicket[msg.sender] = true;
        ticketFunds += msg.value;
        emit TicketPurchased(poolId, msg.sender, false);
    }

    // Zincir reaksiyon için hedef seçme
    function selectChainTarget(uint256 poolId, address target) public {
        require(isEliminated(poolId, msg.sender), "Only eliminated players can select");
        poolFeatures[poolId].chainTarget[msg.sender] = target;
        poolFeatures[poolId].isAtRisk[target] = true;
    }

    // Risk seviyesi belirleme
    function setRiskLevel(uint256 poolId, uint256 level) public {
        require(level <= 3, "Invalid risk level"); // 1: Safe, 2: Risky, 3: Ultra
        poolFeatures[poolId].riskLevel[msg.sender] = level;
    }

    // Eleme şansı hesaplama
    function calculateEliminationChance(uint256 poolId, address player) internal view returns (uint256) {
        PoolFeatures storage pf = poolFeatures[poolId];
        uint256 baseChance = 100;
        
        // Risk seviyesine göre şans ayarla
        if(pf.riskLevel[player] == 2) baseChance *= 2;
        if(pf.riskLevel[player] == 3) baseChance *= 3;
        
        // Zincir hedefi ise şansı artır
        if(pf.isAtRisk[player]) baseChance *= 2;
        
        return baseChance;
    }

    function calculateEliminationCount(uint256 poolId) internal view returns (uint256) {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        
        uint256 baseCount = pool.eliminationCount;
        
        // Kritik turda ise 2 katına çıkar
        if (isInArray(features.criticalRounds, features.currentRound)) {
            baseCount *= 2;
        }
        
        // Son 5 oyuncuda ise 1'e düşür
        if (pool.players.length <= 5) {
            baseCount = 1;
        }
        
        return baseCount;
    }

    function calculateEliminationChances(
        uint256 poolId, 
        address[] memory eligiblePlayers
    ) internal view returns (uint256[] memory) {
        uint256[] memory chances = new uint256[](eligiblePlayers.length);
        PoolFeatures storage features = poolFeatures[poolId];
        
        for(uint256 i = 0; i < eligiblePlayers.length; i++) {
            address player = eligiblePlayers[i];
            uint256 baseChance = 100;
            
            // Risk seviyesine göre şansı ayarla
            if(features.riskLevel[player] == 2) baseChance *= 2;
            if(features.riskLevel[player] == 3) baseChance *= 3;
            
            // Zincir hedefi ise şansı artır
            if(features.isAtRisk[player]) baseChance *= 2;
            
            chances[i] = baseChance;
        }
        
        return chances;
    }

    function processElimination(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        require(features.activeFeatures & FEATURE_CHAIN_ELIMINATION != 0, "Feature not enabled");
        
        // Kurtulma bileti kontrolü
        if (features.hasRescueTicket[player]) {
            features.hasRescueTicket[player] = false;
            features.hasImmunity[player] = true;
            features.immunityExpiry[player] = block.timestamp + 1 hours;
            emit ImmunityGranted(poolId, player, 1 hours);
            return;
        }
        
        // Yaralı kontrolü
        if (features.activeFeatures & FEATURE_DOUBLE_ELIMINATION != 0) {
            if (!features.isWounded[player]) {
                features.isWounded[player] = true;
                emit PlayerWounded(poolId, player);
                return;
            }
        }
        
        // Oyuncuyu havuzdan çıkar
        for(uint256 i = 0; i < pools[poolId].players.length; i++) {
            if(pools[poolId].players[i] == player) {
                pools[poolId].players[i] = pools[poolId].players[pools[poolId].players.length - 1];
                pools[poolId].players.pop();
                break;
            }
        }
        
        // Elenenler listesine ekle
        eliminatedPlayers[poolId].push(player);
        
        // Son oyuncu kontrolü
        if(pools[poolId].players.length <= 5 && !features.isSuddenDeathActive) {
            activateSuddenDeath(poolId);
        }
        
        emit EliminationOccurred(poolId, player);
    }

    function updatePoolState(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        
        // Kritik tur kontrolü
        if(isInArray(features.criticalRounds, features.currentRound)) {
            features.rewardMultiplier += 100; // Ödül çarpanını 1.0 artır
            emit CriticalRoundStarted(poolId, features.currentRound);
        }
        
        // Oyun sonu kontrolü
        if(pool.players.length <= pool.winnerCount) {
            distributeRewards(poolId);
        }
    }

    // Puan ödüllendirme
    function awardPoints(uint256 poolId, address player, uint256 amount) internal {
        poolFeatures[poolId].points[player] += amount;
        checkImmunityThreshold(poolId, player);
    }

    function checkImmunityThreshold(uint256 poolId, address player) internal {
        PoolFeatures storage pf = poolFeatures[poolId];
        if(pf.points[player] >= 100) { // 100 puan = 1 muafiyet
            pf.points[player] -= 100;
            grantImmunity(poolId, player, 1 hours);
        }
    }

    function processCriticalRound(uint256 poolId) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        if(isInArray(features.criticalRounds, features.currentRound)) {
            increaseEliminationCount(poolId);
            
            // features değişkenini daha fazla kullanıyoruz
            features.rewardMultiplier += 100;
            
            // Kritik turda oyuncu seviyelerini kontrol et
            for(uint256 i = 0; i < features.revivalPool.length; i++) {
                address player = features.revivalPool[i];
                // Oyuncu seviyesine göre bonus puanlar ekle
                if (features.playerLevel[player] > 0) {
                    features.points[player] += 10 * features.playerLevel[player];
                }
            }
        }
    }

    function processFinalSurvivors(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        if(pool.players.length <= poolFeatures[poolId].lastSurvivorThreshold) {
            activateSuddenDeath(poolId);
        }
    }

    function configurePoolFeatures(
        uint256 poolId,
        uint256 features,
        uint256[] memory criticalRounds,
        uint256 lastSurvivorThreshold,
        uint256[] memory levelMultipliers
    ) external onlyOwner {
        PoolFeatures storage pf = poolFeatures[poolId];
        pf.activeFeatures = features;
        pf.criticalRounds = criticalRounds;
        pf.lastSurvivorThreshold = lastSurvivorThreshold;
        
        // Level multipliers'ı kullan
        for(uint256 i = 0; i < levelMultipliers.length && i < 4; i++) {
            pf.levelMultipliers[i+1] = levelMultipliers[i];
        }
    }

    function levelUp(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        uint256 currentLevel = features.playerLevel[player];
        require(currentLevel < 4, "Max level reached");
        
        uint256 requiredFee = pools[poolId].entranceFee * (currentLevel + 1);
        require(msg.value == requiredFee, "Incorrect level up fee");
        
        features.playerLevel[player]++;
        features.immunityCount[player] += currentLevel;
        
        if(currentLevel == 4) {
            markForBonusReward(poolId, player);
        }
    }

    function voteForNextElimination(uint256 poolId, uint256 timeChoice) external {
        require(timeChoice >= 1 && timeChoice <= 3, "Invalid time choice");
        PoolFeatures storage features = poolFeatures[poolId];
        features.timeVotes[msg.sender] = timeChoice;
        
        updateEliminationTime(poolId);
    }

    function updateEliminationTime(uint256 poolId) internal {
        // Düzeltilmiş array tanımı
        uint256[] memory times = new uint256[](3);
        times[0] = 1800; // 30min
        times[1] = 3600; // 1h
        times[2] = 7200; // 2h
        
        uint256 mostVotedIndex = calculateMostVotedTime(poolId);
        pools[poolId].eliminationInterval = times[mostVotedIndex];
    }

    function grantImmunity(
        uint256 poolId, 
        address player, 
        uint256 duration
    ) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.immunityCount[player]++;
        features.immunityExpiry[player] = block.timestamp + duration;
        
        emit ImmunityGranted(poolId, player, duration);
    }

    function increaseEliminationCount(
        uint256 poolId
    ) internal returns (uint256) {
        Pool storage pool = pools[poolId];
        if (isCriticalRound(poolId)) {
            pool.eliminationCount *= 2;
        }
        return pool.eliminationCount;
    }

    function increaseRewardMultiplier(
        uint256 poolId, 
        uint256 amount
    ) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.rewardMultiplier += amount;
        
        emit RewardMultiplierIncreased(poolId, amount);
    }

    function awardSurvivorBonus(
        uint256 poolId, 
        address player
    ) internal {
        uint256 bonus = calculateSurvivorBonus(poolId, player);
        rewards[poolId][player] += bonus;
        
        emit SurvivorBonusAwarded(poolId, player, bonus);
    }

    function activateSuddenDeath(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        
        require(pool.players.length <= 5, "Too many players for sudden death");
        
        pool.eliminationInterval = 300; // 5 dakika
        features.isSuddenDeathActive = true;
        
        emit SuddenDeathActivated(poolId);
    }

    function calculateMostVotedTime(uint256 poolId) internal view returns (uint256) {
        // Doğrudan mapping'e erişim yap
        uint256[3] memory votes = [uint256(0), 0, 0];
        
        // Düzeltilmiş dizi tanımlama
        uint256[] memory times = new uint256[](3);
        times[0] = 1800; // 30min
        times[1] = 3600; // 1h
        times[2] = 7200; // 2h
        
        for(uint256 i = 0; i < pools[poolId].players.length; i++) {
            address player = pools[poolId].players[i];
            uint256 vote = poolFeatures[poolId].timeVotes[player];
            if(vote > 0 && vote <= 3) {
                votes[vote-1]++;
                
                if(poolFeatures[poolId].playerLevel[player] > 1) {
                    votes[vote-1] += poolFeatures[poolId].playerLevel[player] - 1;
                }
            }
        }
        
        uint256 maxVotes = 0;
        uint256 selectedTime = 1;
        
        for(uint256 i = 0; i < 3; i++) {
            if(votes[i] > maxVotes) {
                maxVotes = votes[i];
                selectedTime = i + 1;
            }
        }
        
        return selectedTime;
    }

    function calculateBonusAmount(uint256 poolId, address player) internal view returns (uint256) {
        return pools[poolId].entranceFee * poolFeatures[poolId].playerLevel[player];
    }

    function getFirstThreeEliminated(uint256 poolId) internal view returns (address[] memory) {
        require(eliminatedPlayers[poolId].length >= 3, "Not enough eliminations yet");
        
        address[] memory firstThree = new address[](3);
        for(uint256 i = 0; i < 3; i++) {
            firstThree[i] = eliminatedPlayers[poolId][i];
        }
        return firstThree;
    }

    function checkFirstThreeMatch(address guess, address[] memory firstThree) internal pure returns (bool) {
        for(uint256 i = 0; i < firstThree.length; i++) {
            if(firstThree[i] == guess) return true;
        }
        return false;
    }

    // FeaturePoints fonksiyonunu düzelt
    function applyBonuses(
        uint256 reward,
        PoolFeatures storage features
    ) internal view returns (uint256) {
        if (features.activeFeatures & FEATURE_CRITICAL_ROUNDS != 0) {
            if (isInArray(features.criticalRounds, features.currentRound)) {
                reward *= 2;
                if (features.playerLevel[msg.sender] > 2) {
                    reward += features.playerLevel[msg.sender] * 50;
                }
            }
        }
        if (features.playerLevel[msg.sender] > 1) {
            reward += (reward * features.playerLevel[msg.sender] * 10) / 100;
        }
        return reward;
    }

    function applyRiskMultipliers(
        uint256 reward,
        PoolFeatures storage features
    ) internal view returns (uint256) {
        if (features.riskLevel[msg.sender] > 1) {
            reward += (reward * features.riskLevel[msg.sender] * 5) / 100;
        }
        return reward;
    }

    // Seviye çarpanlarını ayarlama
    function setLevelMultiplier(uint256 poolId, uint256 level, uint256 multiplier) external onlyOwner {
        require(level > 0 && level <= 4, "Invalid level");
        require(multiplier > 0, "Invalid multiplier");
        poolFeatures[poolId].levelMultipliers[level] = multiplier;
        emit LevelMultiplierSet(poolId, level, multiplier);
    }

    // İmmünite süresini kontrol etme
    function checkImmunityExpiry(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        if (features.hasImmunity[player] && block.timestamp >= features.immunityExpiry[player]) {
            features.hasImmunity[player] = false;
            emit ImmunityExpired(poolId, player);
        }
    }

    // Tur ilerletme fonksiyonu
    function advanceRound(uint256 poolId) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.currentRound++;
        emit RoundAdvanced(poolId, features.currentRound);
    }

    /**
     * @dev Havuzun mevcut durumunu döndürür
     * @param poolId Havuz ID'si
     * @return isActive Havuz aktif mi
     * @return playerCount Oyuncu sayisi
     * @return eliminatedCount Elenen oyuncu sayisi
     * @return isSuddenDeathActive Ani olum aktif mi
     * @return currentRound Mevcut tur
     */
    function getPoolStatus(uint256 poolId) public view returns (
        bool isActive,
        uint256 playerCount,
        uint256 eliminatedCount,
        bool isSuddenDeathActive,
        uint256 currentRound
    ) {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        
        return (
            pool.active,
            pool.players.length,
            eliminatedPlayers[poolId].length,
            features.isSuddenDeathActive,
            features.currentRound
        );
    }

    // Havuz durumunu kontrol etme
    function getPoolStatus(uint256 poolId) public view returns (
        bool isActive,
        uint256 playerCount,
        uint256 eliminatedCount,
        bool isSuddenDeathActive,
        uint256 currentRound
    ) {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        
        return (
            pool.active,
            pool.players.length,
            eliminatedPlayers[poolId].length,
            features.isSuddenDeathActive,
            features.currentRound
        );
    }

    // Oyuncu bilgilerini getirme
    function getPlayerInfo(uint256 poolId, address player) public view returns (
        uint256 level,
        uint256 points,
        bool hasImmunity,
        uint256 immunityExpiry,
        bool isAtRisk
    ) {
        PoolFeatures storage features = poolFeatures[poolId];
        
        return (
            features.playerLevel[player],
            features.points[player],
            features.hasImmunity[player],
            features.immunityExpiry[player],
            features.isAtRisk[player]
        );
    }

    // Platform ücreti için değişkenler
    address public platformFeeAddress;
    
    /**
     * @dev Platform komisyon adresini değiştirir
     * @param _platformFeeAddress Yeni platform komisyon adresi
     */
    function setPlatformFeeAddress(address _platformFeeAddress) external onlyOwner {
        require(_platformFeeAddress != address(0), "Sifir adres olamaz");
        platformFeeAddress = _platformFeeAddress;
    }
    
    /**
     * @dev Platform komisyon yüzdesini değiştirir
     * @param _platformFeePercentage Yeni yüzde (0-100 arası)
     */
    function setPlatformFeePercentage(uint256 _platformFeePercentage) external onlyOwner {
        require(_platformFeePercentage <= 100, "Yuzde 100'den buyuk olamaz");
        PLATFORM_FEE_PERCENT = _platformFeePercentage;
    }
    
    /**
     * @dev Acil durumda havuzu sonlandırır
     * @param poolId Sonlandırılacak havuz ID'si
     */
    function emergencyCompletePool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Havuz zaten tamamlanmis");
        
        // Havuzu tamamla
        pool.active = false;
        
        // Ödül dağıtımı yap
        distributeRewards(poolId);
    }
    
    /**
     * @dev Havuzu duraklatır
     * @param poolId Duraklatılacak havuz ID'si
     */
    function pausePool(uint256 poolId) external onlyOwner {
        require(pools[poolId].active, "Havuz aktif degil");
        require(!pausedPools[poolId], "Havuz zaten duraklatilmis");
        
        pausedPools[poolId] = true;
    }
    
    /**
     * @dev Duraklatılmış havuzu devam ettirir
     * @param poolId Devam ettirilecek havuz ID'si
     */
    function resumePool(uint256 poolId) external onlyOwner {
        require(pools[poolId].active, "Havuz aktif degil");
        require(pausedPools[poolId], "Havuz zaten devam ediyor");
        
        pausedPools[poolId] = false;
    }
    
    /**
     * @dev Havuzun özellik bayraklarını günceller
     * @param poolId Güncellenecek havuz ID'si
     * @param features Yeni özellik bayrakları
     */
    function updatePoolFeatures(uint256 poolId, uint256 features) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Havuz aktif degil");
        
        // Zincir eleme kontrolü - teste göre çift eleme ile zincir eleme birlikte kullanılamıyor
        if ((features & FEATURE_CHAIN_ELIMINATION) != 0) {
            require(pool.eliminationCount == 1, "Chain elimination requires single eliminations");
        }
        
        poolFeatures[poolId].activeFeatures = features;
    }
    
    /**
     * @dev Kontrat bakiyesinden para çeker
     * @param recipient Fonların gönderileceği adres
     * @param amount Çekilecek miktar
     */
    function withdrawFunds(address recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0), "Sifir adres olamaz");
        require(address(this).balance >= amount, "Yetersiz bakiye");
        
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Para transferi basarisiz");
    }
    
    // Paused havuzları için mapping 
    mapping(uint256 => bool) public pausedPools;
    
    /**
     * @dev Belirli bir havuzun platform komisyonunu çeker
     * @param poolId Komisyonu çekilecek havuz ID'si
     */
    function withdrawPlatformFee(uint256 poolId) external onlyOwner nonReentrant {
        Pool storage pool = pools[poolId];
        require(!pool.active, "Havuz hala aktif");
        
        uint256 totalPoolAmount = pool.entranceFee * pool.players.length;
        uint256 platformFee = (totalPoolAmount * PLATFORM_FEE_PERCENT) / 100;
        
        address recipient = platformFeeAddress != address(0) ? platformFeeAddress : owner;
        (bool success, ) = payable(recipient).call{value: platformFee}("");
        require(success, "Platform komisyonu transferi basarisiz");
    }
    
    /**
     * @dev Temel havuz bilgilerini döndürür
     * @param poolId Havuz ID'si
     * @return playerCount Oyuncu sayısı
     * @return eliminatedCount Elenen oyuncu sayısı
     * @return maxPlayers Maksimum oyuncu sayısı
     * @return entranceFee Giriş ücreti
     * @return winnerCount Kazanan sayısı
     */
    function getBasicPoolInfo(uint256 poolId) external view returns (
        uint256 playerCount,
        uint256 eliminatedCount,
        uint256 maxPlayers,
        uint256 entranceFee,
        uint256 winnerCount
    ) {
        Pool storage pool = pools[poolId];
        return (
            pool.players.length,
            eliminatedPlayers[poolId].length,
            pool.maxPlayers,
            pool.entranceFee,
            pool.winnerCount
        );
    }

    /**
     * @dev Gelişmiş havuz bilgilerini döndürür
     * @param poolId Havuz ID'si
     * @return eliminationCount Eleme sayısı
     * @return eliminationInterval Eleme aralığı
     * @return features Özellik bayrakları
     * @return endTime Bitiş zamanı
     * @return betFund Bahis fonu
     */
    function getAdvancedPoolInfo(uint256 poolId) external view returns (
        uint256 eliminationCount,
        uint256 eliminationInterval,
        uint256 features,
        uint256 endTime,
        uint256 betFund
    ) {
        Pool storage pool = pools[poolId];
        return (
            pool.eliminationCount,
            pool.eliminationInterval,
            poolFeatures[poolId].activeFeatures,
            pool.active ? 0 : block.timestamp,
            betFunds[poolId]
        );
    }

    /**
     * @dev Toplam yerleştirilen bahis sayısını döndürür
     * @return Toplam bahis sayısı
     */
    function totalBetsPlaced() external view returns (uint256) {
        uint256 total = 0;
        
        for (uint256 i = 1; i <= poolCounter; i++) {
            total += bets[i].length;
        }
        
        return total;
    }
    
    /**
     * @dev Havuzu tamamlar (ödülleri dağıtır)
     * @param poolId Tamamlanacak havuz ID'si
     */
    function completePool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Havuz aktif degil");
        
        // Havuzu tamamla ve ödülleri dağıt
        distributeRewards(poolId);
    }

    /**
     * @dev Havuzun giriş ücretini değiştirir
     * @param poolId Güncellenecek havuz ID'si
     * @param newFee Yeni giriş ücreti
     */
    function updateEntranceFee(uint256 poolId, uint256 newFee) external onlyOwner {
        require(pools[poolId].active, "Havuz aktif degil");
        require(newFee > 0, "Ucret sifir olamaz");
        pools[poolId].entranceFee = newFee;
    }

    /**
     * @dev Kurtarma ve iyileştirme bileti fiyatlarını günceller
     * @param poolId Güncellenecek havuz ID'si
     * @param rescuePrice Yeni kurtarma bileti fiyatı
     * @param healingPrice Yeni iyileştirme bileti fiyatı
     */
    function updateTicketPrices(uint256 poolId, uint256 rescuePrice, uint256 healingPrice) external onlyOwner {
        require(pools[poolId].active, "Havuz aktif degil");
        require(rescuePrice > 0, "Kurtarma bileti ucreti sifir olamaz");
        require(healingPrice > 0, "Iyilestirme bileti ucreti sifir olamaz");
        
        PoolFeatures storage features = poolFeatures[poolId];
        features.rescueTicketPrice = rescuePrice;
        features.healingTicketPrice = healingPrice;
    }

    /**
     * @dev Havuz ödül çarpanını günceller
     * @param poolId Güncellenecek havuz ID'si
     * @param multiplier Yeni ödül çarpanı
     */
    function updateRewardMultiplier(uint256 poolId, uint256 multiplier) external onlyOwner {
        require(pools[poolId].active, "Havuz aktif degil");
        require(multiplier > 0, "Odul carpani sifir olamaz");
        
        poolFeatures[poolId].rewardMultiplier = multiplier;
        emit RewardMultiplierIncreased(poolId, multiplier);
    }

    /**
     * @dev Kazanan sayısını günceller
     * @param poolId Güncellenecek havuz ID'si
     * @param newWinnerCount Yeni kazanan sayısı
     */
    function updateWinnerCount(uint256 poolId, uint256 newWinnerCount) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Havuz aktif degil");
        require(newWinnerCount > 0, "Kazanan sayisi sifir olamaz");
        require(newWinnerCount < pool.maxPlayers, "Kazanan sayisi maksimum oyuncu sayisindan az olmali");
        
        pool.winnerCount = newWinnerCount;
    }

    /**
     * @dev Eleme aralığını günceller
     * @param poolId Güncellenecek havuz ID'si
     * @param newInterval Yeni eleme aralığı (saniye cinsinden)
     */
    function updateEliminationInterval(uint256 poolId, uint256 newInterval) external onlyOwner {
        require(pools[poolId].active, "Havuz aktif degil");
        require(newInterval >= 300, "Eleme araligi minimum 5 dakika olmali");
        
        pools[poolId].eliminationInterval = newInterval;
    }

    /**
     * @dev Tur başına elenen oyuncu sayısını günceller
     * @param poolId Güncellenecek havuz ID'si
     * @param newCount Yeni eleme sayısı
     */
    function updateEliminationCount(uint256 poolId, uint256 newCount) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Havuz aktif degil");
        require(newCount > 0, "Eleme sayisi sifir olamaz");
        require(newCount < pool.players.length, "Eleme sayisi oyuncu sayisindan az olmali");
        
        // Zincir eleme özelliği kontrolü
        if (poolFeatures[poolId].activeFeatures & FEATURE_CHAIN_ELIMINATION != 0) {
            require(newCount == 1, "Zincir eleme ozelligi aktifken yalnizca 1 oyuncu elenebilir");
        }
        
        pool.eliminationCount = newCount;
    }

    // For receiving Ether
    receive() external payable {}
    fallback() external payable {}
    
    /* -------------
       TEST FUNCTIONS
       ------------- */
    
    function devSetupTestPool() external onlyOwner {
        createPool(
            1 ether,              // entranceFee
            5,                    // maxPlayers
            3600,                 // eliminationInterval
            1,                    // eliminationCount
            3,                    // winnerCount
            FEATURE_CHAIN_ELIMINATION | FEATURE_CRITICAL_ROUNDS,  // features
            0.1 ether,            // rescueTicketPrice
            0.05 ether,           // healingTicketPrice
            120,                  // accelerationRate
            200                   // criticalMultiplier
        );
    }

    function testFullCycle() external onlyOwner {
        // Test havuzu için temel parametreler
        uint256 entranceFee = 1 ether;
        uint256 maxPlayers = 10;
        uint256 eliminationInterval = 3600;
        uint256 eliminationCount = 1;
        uint256 winnerCount = 3;
        
        // Kritik tur parametreleri
        uint256[] memory criticalRounds = new uint256[](2);
        criticalRounds[0] = 3;
        criticalRounds[1] = 6;

        // Havuz özellikleri
        uint256 features = FEATURE_CHAIN_ELIMINATION |
                          FEATURE_CRITICAL_ROUNDS |
                          FEATURE_LEVEL_SYSTEM |
                          FEATURE_RISK_LEVELS |
                          FEATURE_POINT_SYSTEM |
                          FEATURE_SUDDEN_DEATH;

        // Test havuzu oluştur
        createPool(
            entranceFee,
            maxPlayers,
            eliminationInterval,
            eliminationCount,
            winnerCount,
            features,
            0.1 ether, // rescueTicketPrice
            0.05 ether, // healingTicketPrice
            120, // accelerationRate
            200  // criticalMultiplier
        );

        // Bahis tiplerini test et
        createBetType(
            "First 3 Order",
            "First three eliminations in order",
            300,
            10,
            1,
            true,
            false
        );

        // ... diğer test kodları aynı kalacak ...
    }

    // 1. isEliminated fonksiyonu
    function isEliminated(uint256 poolId, address player) internal view returns (bool) {
        for(uint256 i = 0; i < eliminatedPlayers[poolId].length; i++) {
            if(eliminatedPlayers[poolId][i] == player) return true;
        }
        return false;
    }

    // 2. getEligiblePlayers fonksiyonu
    function getEligiblePlayers(uint256 poolId) internal view returns (address[] memory) {
        Pool storage pool = pools[poolId];
        uint256 count = 0;
        
        // Uygun oyuncu sayısını hesapla
        for(uint256 i = 0; i < pool.players.length; i++) {
            if(!poolFeatures[poolId].hasImmunity[pool.players[i]]) {
                count++;
            }
        }
        
        // Uygun oyuncuları diziye ekle
        address[] memory eligiblePlayers = new address[](count);
        uint256 index = 0;
        for(uint256 i = 0; i < pool.players.length; i++) {
            if(!poolFeatures[poolId].hasImmunity[pool.players[i]]) {
                eligiblePlayers[index] = pool.players[i];
                index++;
            }
        }
        
        return eligiblePlayers;
    }

    // 3. selectWeightedRandom fonksiyonu
    function selectWeightedRandom(
        uint256 poolId,
        address[] memory players,
        uint256[] memory weights
    ) internal view returns (address) {
        require(players.length == weights.length, "Length mismatch");
        require(players.length > 0, "Empty player array");
        
        uint256 totalWeight = 0;
        for(uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            poolId
        ))) % totalWeight;
        
        uint256 cumulativeWeight = 0;
        for(uint256 i = 0; i < weights.length; i++) {
            cumulativeWeight += weights[i];
            if(randomNumber < cumulativeWeight) {
                return players[i];
            }
        }
        
        return players[0];
    }

    // 4. markAdjacentPlayersAtRisk fonksiyonu
    function markAdjacentPlayersAtRisk(uint256 poolId, address player) internal {
        Pool storage pool = pools[poolId];
        uint256 playerIndex = 0;
        
        // Oyuncunun indexini bul
        for(uint256 i = 0; i < pool.players.length; i++) {
            if(pool.players[i] == player) {
                playerIndex = i;
                break;
            }
        }
        
        // Komşu oyuncuları riskli olarak işaretle
        if(playerIndex > 0) {
            poolFeatures[poolId].isAtRisk[pool.players[playerIndex-1]] = true;
        }
        if(playerIndex < pool.players.length-1) {
            poolFeatures[poolId].isAtRisk[pool.players[playerIndex+1]] = true;
        }
    }

    // 5. isCriticalRound fonksiyonu
    function isCriticalRound(uint256 poolId) internal view returns (bool) {
        return isInArray(poolFeatures[poolId].criticalRounds, poolFeatures[poolId].currentRound);
    }

    // 6. calculateSurvivorBonus fonksiyonu
    function calculateSurvivorBonus(uint256 poolId, address player) internal view returns (uint256) {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        
        uint256 baseBonus = pool.entranceFee;
        uint256 levelMultiplier = features.playerLevel[player];
        
        return baseBonus * levelMultiplier * features.rewardMultiplier / 100;
    }

    // 7. markForBonusReward fonksiyonu
    function markForBonusReward(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.hasBonusReward[player] = true;
        features.bonusAmount[player] = calculateBonusAmount(poolId, player);
        
        emit BonusRewardMarked(poolId, player);
    }
}
