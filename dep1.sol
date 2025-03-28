// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MonadSurvive {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    enum PoolRuleType { Standard, WithMaxBet }
    enum BetRuleType { 
        None,
        FirstThreeInOrder,
        LastFiveAnyOrder,
        MostBettedThree,
        FirstHourEliminated,
        GroupElimination,
        CombinationBet,
        TimeBasedElimination,
        StatisticsBased,
        TenthEliminated,
        LastN
    }
    
    struct Pool {
        uint256 id;
        uint256 startTime;
        uint256 entranceFee;
        uint256 maxPlayers;
        uint256 eliminationInterval;
        uint256 eliminationCount;
        uint256 winnerCount;
        bool active;
        address[] players;
        PoolRuleType poolRule;
        BetRuleType betRule;
        uint256 betTarget;
    }
    
    struct Bet {
        address player;
        uint256 amount;
        address guess;
    }
    
    struct BetType {
        string name;
        string description;
        uint256 minPlayers;
        uint256 rewardMultiplier;
        bool requiresOrder;
        bool isGroupBet;
        bool isTimeBased;
        uint256 timeLimit;
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

    struct BetTypeConfig {
        string name;
        string description;
        bool isActive;
        uint256 multiplier;
        uint256 minPlayers;
        uint256 maxWinners;
        bool requiresOrder;
        bool allowsMultiple;
        uint256 timeLimit;
    }
    
    struct TimeVote {
        uint256 fast;
        uint256 normal;
        uint256 slow;
    }
    
    uint256 constant FEATURE_CHAIN_ELIMINATION = 1;
    uint256 constant FEATURE_LAST_SURVIVOR = 2;
    uint256 constant FEATURE_CRITICAL_ROUNDS = 4;
    uint256 constant FEATURE_LEVEL_SYSTEM = 8;
    uint256 constant FEATURE_REVIVAL_POOL = 16;
    uint256 constant FEATURE_DYNAMIC_TIMING = 32;
    uint256 constant FEATURE_RISK_LEVELS = 64;
    uint256 constant FEATURE_POINT_SYSTEM = 128;
    uint256 constant FEATURE_SUDDEN_DEATH = 256;
    uint256 constant FEATURE_RESCUE_TICKET = 512;
    uint256 constant FEATURE_HEALING_TICKET = 1024;
    uint256 constant FEATURE_DOUBLE_ELIMINATION = 2048;

    struct PoolFeatures {
        uint256 activeFeatures;
        uint256 lastSurvivorThreshold;
        mapping(address => uint256) riskLevel;
        mapping(address => uint256) points;
        mapping(address => uint256) immunityCount;
        mapping(address => address) chainTarget;
        uint256[] criticalRounds;
        uint256 currentRound;
        mapping(address => uint256) playerLevel;
        mapping(uint256 => uint256) levelMultipliers;
        address[] revivalPool;
        mapping(address => bool) isAtRisk;
        mapping(address => uint256) timeVotes;
        uint256 nextEliminationTime;
        mapping(address => bool) hasImmunity;
        mapping(address => uint256) immunityExpiry;
        uint256 rewardMultiplier;
        mapping(address => bool) hasBonusReward;
        mapping(address => uint256) bonusAmount;
        bool isSuddenDeathActive;
        uint256 rescueTicketPrice;
        uint256 healingTicketPrice;
        mapping(address => bool) hasRescueTicket;
        mapping(address => bool) hasHealingTicket;
        mapping(address => bool) isWounded;
    }

    address public owner;
    uint256 public poolCounter;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => uint256) public poolFunds;
    mapping(uint256 => uint256) public betFunds;
    mapping(uint256 => Bet[]) public bets;
    mapping(uint256 => address[]) public eliminatedPlayers;
    mapping(uint256 => mapping(address => uint256)) public betVotes;
    mapping(uint256 => mapping(address => uint256)) public rewards;
    mapping(uint256 => AdvancedBetConfig) public betConfigs;
    mapping(uint256 => mapping(uint256 => bool)) public poolActiveBetTypes;
    mapping(uint256 => uint256[]) public poolBetTypes;
    mapping(uint256 => BetTypeConfig) public betTypeConfigs;
    uint256 public betTypeCounter;
    mapping(uint256 => PoolFeatures) public poolFeatures;
    uint256 public ticketFunds;
    uint256 public PLATFORM_FEE_PERCENT = 10;
    uint256 public collectedPlatformFees;
    mapping(address => uint256) public ticketExpiry;
    uint256 public constant TICKET_VALIDITY = 24 hours;
    
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
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }
    
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
        require(rescueTicketPrice > 0, "Invalid rescue");
        require(healingTicketPrice > 0, "Invalid healing");
        require(accelerationRate >= 100 && accelerationRate <= 500, "Invalid acceleration");
        require(criticalMultiplier > 100 && criticalMultiplier <= 500, "Invalid multiplier");
        require(entranceFee > 0, "Invalid fee");
        require(maxPlayers >= 5, "Min players");
        require(eliminationInterval >= 300, "Min interval");
        require(eliminationCount > 0 && eliminationCount < maxPlayers, "Invalid count");
        require(winnerCount > 0 && winnerCount < maxPlayers, "Invalid winner");
        require(maxPlayers > winnerCount, "Max players");

        if(poolFeaturesFlag & FEATURE_CHAIN_ELIMINATION != 0) {
            require(eliminationCount == 1, "Chain elimination");
        }

        if(poolFeaturesFlag & FEATURE_CRITICAL_ROUNDS != 0) {
            require(criticalMultiplier > 100, "Invalid multiplier");
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

        PoolFeatures storage features = poolFeatures[poolCounter];
        features.activeFeatures = poolFeaturesFlag;
        features.rewardMultiplier = 1;
        features.isSuddenDeathActive = false;
        features.rescueTicketPrice = rescueTicketPrice;
        features.healingTicketPrice = healingTicketPrice;
        features.lastSurvivorThreshold = 5;
        features.nextEliminationTime = block.timestamp + (eliminationInterval / accelerationRate);

        emit PoolCreated(poolCounter, newPool.startTime, entranceFee, maxPlayers, PoolRuleType.Standard, BetRuleType.None, 0);
    }

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

        PoolFeatures storage pf = poolFeatures[poolCounter];
        pf.activeFeatures = featuresFlag;
        pf.rewardMultiplier = 1;
        pf.isSuddenDeathActive = false;
        pf.lastSurvivorThreshold = lastSurvivorThreshold;
        
        for(uint256 i = 0; i < criticalRounds.length; i++) {
            pf.criticalRounds.push(criticalRounds[i]);
        }

        for(uint256 i = 0; i < levelMultipliers.length && i < 4; i++) {
            pf.levelMultipliers[i+1] = levelMultipliers[i];
        }

        emit PoolCreated(poolCounter, newPool.startTime, entranceFee, maxPlayers, PoolRuleType.Standard, BetRuleType.None, 0);
        return poolCounter;
    }
    
    function joinPool(uint256 poolId) external payable {
        require(pools[poolId].active, "Inactive");
        require(msg.value == pools[poolId].entranceFee, "Incorrect fee");
        require(pools[poolId].players.length < pools[poolId].maxPlayers, "Full");
        require(!isEliminated(poolId, msg.sender), "Eliminated");
        require(!poolFeatures[poolId].isWounded[msg.sender], "Wounded");
        
        pools[poolId].players.push(msg.sender);
        
        if(pools[poolId].players.length == pools[poolId].maxPlayers) {
            pools[poolId].startTime = block.timestamp;
        }
        
        poolFunds[poolId] += msg.value;
        emit JoinedPool(poolId, msg.sender);
    }
    
    function placeBet(uint256 poolId, address guess) external payable {
        Pool storage pool = pools[poolId];
        require(pool.active, "Inactive");
        require(msg.value > 0, "Zero bet");
        
        validateBetType(poolId, pool.betRule, guess);
        
        bets[poolId].push(Bet(msg.sender, msg.value, guess));
        betFunds[poolId] += msg.value;
        emit BetPlaced(poolId, msg.sender, msg.value, guess);
    }

    function validateBetType(uint256 poolId, BetRuleType betRule, address guess) internal view {
        Pool storage pool = pools[poolId];
        
        if (betRule == BetRuleType.FirstThreeInOrder) {
            require(eliminatedPlayers[poolId].length < 3, "Eliminated");
        } 
        else if (betRule == BetRuleType.LastFiveAnyOrder) {
            require(pool.players.length <= 5, "Too many");
        }
        else if (betRule == BetRuleType.GroupElimination) {
            require(isInArray(pool.players, guess), "Invalid");
        }
    }
    
    function eliminate(uint256 poolId) public onlyOwner {
        Pool storage pool = pools[poolId]; 
        PoolFeatures storage features = poolFeatures[poolId];

        address[] memory eligiblePlayers = getEligiblePlayers(poolId);
        uint256[] memory chances = calculateEliminationChances(poolId, eligiblePlayers);
        address playerToEliminate = selectWeightedRandom(poolId, eligiblePlayers, chances);

        if(features.activeFeatures & FEATURE_CHAIN_ELIMINATION != 0) {
            markAdjacentPlayersAtRisk(poolId, playerToEliminate);
        }

        if (pool.players.length <= 5) {
            activateSuddenDeath(poolId);
        }
        
        processElimination(poolId, playerToEliminate);
        processBetWinners(poolId, playerToEliminate);
        
        if (isCriticalRound(poolId)) {
            pool.eliminationCount *= 2;
        }
        
        updatePoolState(poolId);
    }
    
    function distributeRewards(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        pool.active = false;
        
        uint256 totalPoolFunds = poolFunds[poolId];
        uint256 platformFee = (totalPoolFunds * PLATFORM_FEE_PERCENT) / 100;
        collectedPlatformFees += platformFee;
        uint256 rewardPool = totalPoolFunds - platformFee;
        uint256 poolShare = rewardPool / pool.players.length;
        
        for (uint256 i = 0; i < pool.players.length; i++) {
            rewards[poolId][pool.players[i]] += poolShare;
        }
        emit WinnerSelected(poolId, pool.players);
        
        processBetRewards(poolId);
    }
    
    function processBetRewards(uint256 poolId) internal {
        uint256 totalBetFunds = betFunds[poolId];
        if(totalBetFunds == 0) return;
        
        Pool storage pool = pools[poolId];
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

    function processFirstThreeInOrderBets(uint256 poolId) internal {
        address[] memory firstThree = getFirstThreeEliminated(poolId);
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            Bet storage bet = bets[poolId][i];
            if (checkFirstThreeMatch(bet.guess, firstThree)) {
                uint256 reward = calculateBetReward(poolId, bet.amount, 3);
                rewards[poolId][bet.player] += reward;
                emit BetWon(poolId, bet.player, reward, bet.guess);
            }
        }
    }

  function processLastFiveAnyOrderBets(uint256 poolId) internal {
    Pool storage pool = pools[poolId];
    require(pool.active, "Inactive pool"); // Havuzun aktif olduğunu kontrol ediyoruz
    require(pool.players.length <= 5, "Too many players");

    // Process bets for last five players in any order
    for (uint256 i = 0; i < bets[poolId].length; i++) {
        Bet storage bet = bets[poolId][i];
        if (isInArray(pool.players, bet.guess)) {
            uint256 reward = calculateBetReward(poolId, bet.amount, 4);
            rewards[poolId][bet.player] += reward;
            emit BetWon(poolId, bet.player, reward, bet.guess);
        }
    }
}

   function processGroupEliminationBets(uint256 poolId) internal {
    Pool storage pool = pools[poolId];
    require(pool.active, "Inactive pool"); // Havuzun aktif olduğunu kontrol ediyoruz

    // Process group elimination bets
    for (uint256 i = 0; i < bets[poolId].length; i++) {
        Bet storage bet = bets[poolId][i];
        if (isEliminated(poolId, bet.guess)) {
            uint256 reward = calculateBetReward(poolId, bet.amount, 3);
            rewards[poolId][bet.player] += reward;
            emit BetWon(poolId, bet.player, reward, bet.guess);
        }
    }
}

    function processFirstHourBets(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        uint256 firstHour = pool.startTime + 1 hours;
        
        // Process first hour elimination bets
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            Bet storage bet = bets[poolId][i];
            if (isEliminated(poolId, bet.guess) && block.timestamp <= firstHour) {
                uint256 reward = calculateBetReward(poolId, bet.amount, 5);
                rewards[poolId][bet.player] += reward;
                emit BetWon(poolId, bet.player, reward, bet.guess);
            }
        }
    }

    function processMostBettedBets(uint256 poolId) internal {
        // Process bets for most betted players
        uint256[] memory betCounts = new uint256[](pools[poolId].maxPlayers);
        address[] memory players = pools[poolId].players;
        
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            for (uint256 j = 0; j < players.length; j++) {
                if (bets[poolId][i].guess == players[j]) {
                    betCounts[j]++;
                }
            }
        }
        
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            Bet storage bet = bets[poolId][i];
            if (isInTopThreeBets(bet.guess, players, betCounts)) {
                uint256 reward = calculateBetReward(poolId, bet.amount, 3);
                rewards[poolId][bet.player] += reward;
                emit BetWon(poolId, bet.player, reward, bet.guess);
            }
        }
    }

    function processCombinationBets(uint256 poolId) internal {
        // Process combination bets
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            Bet storage bet = bets[poolId][i];
            if (isValidCombination(poolId, bet.guess)) {
                uint256 reward = calculateBetReward(poolId, bet.amount, 6);
                rewards[poolId][bet.player] += reward;
                emit BetWon(poolId, bet.player, reward, bet.guess);
            }
        }
    }

    function processTimeBasedBets(uint256 poolId) internal {
    Pool storage pool = pools[poolId];
    require(pool.active, "Inactive pool"); // Havuzun aktif olduğunu kontrol ediyoruz

    // Process time-based elimination bets
    for (uint256 i = 0; i < bets[poolId].length; i++) {
        Bet storage bet = bets[poolId][i];
        if (isEliminated(poolId, bet.guess)) {
            uint256 reward = calculateBetReward(poolId, bet.amount, 2);
            rewards[poolId][bet.player] += reward;
            emit BetWon(poolId, bet.player, reward, bet.guess);
        }
    }
}

    function processStatisticsBets(uint256 poolId) internal {
    Pool storage pool = pools[poolId];
    require(pool.active, "Inactive pool"); // Havuzun aktif olduğunu kontrol ediyoruz

    // Process statistics-based bets
    for (uint256 i = 0; i < bets[poolId].length; i++) {
        Bet storage bet = bets[poolId][i];
        if (isValidStatisticsBet(poolId, bet.guess)) {
            uint256 reward = calculateBetReward(poolId, bet.amount, 4);
            rewards[poolId][bet.player] += reward;
            emit BetWon(poolId, bet.player, reward, bet.guess);
        }
    }
}

    // Helper functions for bet processing
    function isInTopThreeBets(address player, address[] memory players, uint256[] memory betCounts) internal pure returns (bool) {
        uint256 playerBets = 0;
        uint256 playerIndex = 0;
        
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                playerBets = betCounts[i];
                playerIndex = i;
                break;
            }
        }
        
        uint256 higherCounts = 0;
        for (uint256 i = 0; i < betCounts.length; i++) {
            if (i != playerIndex && betCounts[i] > playerBets) {
                higherCounts++;
            }
        }
        
        return higherCounts < 3;
    }

    function isValidCombination(uint256 poolId, address player) internal view returns (bool) {
        return isEliminated(poolId, player);
    }

    function isValidStatisticsBet(uint256 poolId, address player) internal view returns (bool) {
        return isEliminated(poolId, player);
    }

    function claimReward(uint256 poolId) external nonReentrant {
        uint256 rewardAmount = rewards[poolId][msg.sender];
        require(rewardAmount > 0, "No reward");
        rewards[poolId][msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "Transfer failed");
        emit RewardClaimed(poolId, msg.sender, rewardAmount);
    }
    
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = collectedPlatformFees + ticketFunds;
        require(amount > 0, "No fees");
        collectedPlatformFees = 0;
        ticketFunds = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getPoolPlayers(uint256 poolId) public view returns (address[] memory) {
        return pools[poolId].players;
    }
    
    function isInArray(address[] memory array, address addr) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == addr) return true;
        }
        return false;
    }

    function isInArray(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) return true;
        }
        return false;
    }
    
    function validateBet(uint256 poolId, BetRuleType betRule) internal view {
        require(pools[poolId].active, "Inactive");
        require(pools[poolId].maxPlayers > 0, "Invalid config");
        require(pools[poolId].entranceFee > 0, "Invalid fee");
        require(pools[poolId].eliminationInterval > 0, "Invalid interval");
        
        if(betRule == BetRuleType.TenthEliminated) {
            validateTenthElimination(pools[poolId]);
        } else if(betRule == BetRuleType.LastN) {
            validateLastN(pools[poolId]);
        }
    }

    function validateTenthElimination(Pool storage pool) internal view {
        require(pool.maxPlayers >= 10, "Capacity");
        require(pool.eliminationCount > 0, "Invalid count");
    }

    function validateLastN(Pool storage pool) internal view {
        require(pool.maxPlayers > pool.winnerCount, "Capacity");
        require(pool.players.length >= pool.winnerCount, "Not enough");
        require(block.timestamp >= pool.startTime, "Not started");
    }

    function calculateBetReward(
        uint256 poolId,
        uint256 betAmount,
        uint256 multiplier
    ) internal view returns (uint256) {
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

    function addBetTypeConfig(
        string memory _name,
        string memory _description,
        uint256 _multiplier,
        uint256 _minPlayers,
        bool _isTimeBased,
        uint256 _timeLimit
    ) external onlyOwner {
        betTypeCounter++;
        betTypeConfigs[betTypeCounter] = BetTypeConfig(_name, _description, true, _multiplier, _minPlayers, 1, _isTimeBased, false, _timeLimit);
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
        betConfigs[betTypeId] = AdvancedBetConfig(name, description, minPlayers, rewardMultiplier, timeLimit, requiresSequence, isTeamBased, allowsMultipleGuesses);
    }

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
        betTypeConfigs[betTypeCounter] = BetTypeConfig(_name, _description, true, _multiplier, _minPlayers, _maxWinners, _requiresOrder, _allowsMultiple, 0);
        emit BetTypeCreated(betTypeCounter, _name, _multiplier);
        return betTypeCounter;
    }

    function addBetTypeToPool(uint256 _poolId, uint256 _betTypeId) public onlyOwner {
        require(pools[_poolId].active, "Inactive");
        require(betTypeConfigs[_betTypeId].isActive, "Inactive type");
        require(!poolActiveBetTypes[_poolId][_betTypeId], "Already added");
        poolActiveBetTypes[_poolId][_betTypeId] = true;
        poolBetTypes[_poolId].push(_betTypeId);
        emit BetTypeAddedToPool(_poolId, _betTypeId);
    }

    function removeBetTypeFromPool(uint256 _poolId, uint256 _betTypeId) external onlyOwner {
        require(pools[_poolId].active, "Inactive");
        require(poolActiveBetTypes[_poolId][_betTypeId], "Not in pool");
        poolActiveBetTypes[_poolId][_betTypeId] = false;
        emit BetTypeRemovedFromPool(_poolId, _betTypeId);
    }

    function updateBetMultiplier(uint256 _betTypeId, uint256 _newMultiplier) external onlyOwner {
        require(betTypeConfigs[_betTypeId].isActive, "Inactive");
        betTypeConfigs[_betTypeId].multiplier = _newMultiplier;
        emit BetMultiplierUpdated(_betTypeId, _newMultiplier);
    }

    function getPoolActiveBetTypes(uint256 _poolId) external view returns (uint256[] memory activeBetTypes) {
        uint256[] memory allTypes = poolBetTypes[_poolId];
        uint256 activeCount = 0;
        for(uint256 i = 0; i < allTypes.length; i++) {
            if(poolActiveBetTypes[_poolId][allTypes[i]]) activeCount++;
        }
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

    function purchaseRescueTicket(uint256 poolId) external payable {
        PoolFeatures storage features = poolFeatures[poolId];
        require(features.activeFeatures & FEATURE_RESCUE_TICKET != 0, "Disabled");
        require(msg.value == features.rescueTicketPrice, "Incorrect price");
        require(!features.hasRescueTicket[msg.sender], "Already has");
        features.hasRescueTicket[msg.sender] = true;
        ticketFunds += msg.value;
        emit TicketPurchased(poolId, msg.sender, true);
    }

    function purchaseHealingTicket(uint256 poolId) external payable {
        PoolFeatures storage features = poolFeatures[poolId];
        require(features.activeFeatures & FEATURE_HEALING_TICKET != 0, "Disabled");
        require(msg.value == features.healingTicketPrice, "Incorrect price");
        require(features.isWounded[msg.sender], "Not wounded");
        features.hasHealingTicket[msg.sender] = true;
        ticketFunds += msg.value;
        emit TicketPurchased(poolId, msg.sender, false);
    }

    function selectChainTarget(uint256 poolId, address target) public {
        require(isEliminated(poolId, msg.sender), "Not eliminated");
        poolFeatures[poolId].chainTarget[msg.sender] = target;
        poolFeatures[poolId].isAtRisk[target] = true;
    }

    function setRiskLevel(uint256 poolId, uint256 level) public {
        require(level <= 3, "Invalid level");
        poolFeatures[poolId].riskLevel[msg.sender] = level;
    }

    function calculateEliminationChance(uint256 poolId, address player) internal view returns (uint256) {
        PoolFeatures storage pf = poolFeatures[poolId];
        uint256 baseChance = 100;
        if(pf.riskLevel[player] == 2) baseChance *= 2;
        if(pf.riskLevel[player] == 3) baseChance *= 3;
        if(pf.isAtRisk[player]) baseChance *= 2;
        return baseChance;
    }

    function calculateEliminationCount(uint256 poolId) internal view returns (uint256) {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        uint256 baseCount = pool.eliminationCount;
        if (isInArray(features.criticalRounds, features.currentRound)) baseCount *= 2;
        if (pool.players.length <= 5) baseCount = 1;
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
            if(features.riskLevel[player] == 2) baseChance *= 2;
            if(features.riskLevel[player] == 3) baseChance *= 3;
            if(features.isAtRisk[player]) baseChance *= 2;
            chances[i] = baseChance;
        }
        return chances;
    }

    function processElimination(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        require(features.activeFeatures & FEATURE_CHAIN_ELIMINATION != 0, "Disabled");
        if (features.hasRescueTicket[player]) {
            features.hasRescueTicket[player] = false;
            features.hasImmunity[player] = true;
            features.immunityExpiry[player] = block.timestamp + 1 hours;
            emit ImmunityGranted(poolId, player, 1 hours);
            return;
        }
        if (features.activeFeatures & FEATURE_DOUBLE_ELIMINATION != 0) {
            if (!features.isWounded[player]) {
                features.isWounded[player] = true;
                emit PlayerWounded(poolId, player);
                return;
            }
        }
        for(uint256 i = 0; i < pools[poolId].players.length; i++) {
            if(pools[poolId].players[i] == player) {
                pools[poolId].players[i] = pools[poolId].players[pools[poolId].players.length - 1];
                pools[poolId].players.pop();
                break;
            }
        }
        eliminatedPlayers[poolId].push(player);
        if(pools[poolId].players.length <= 5 && !features.isSuddenDeathActive) {
            activateSuddenDeath(poolId);
        }
        emit EliminationOccurred(poolId, player);
    }

    function updatePoolState(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        if(isInArray(features.criticalRounds, features.currentRound)) {
            features.rewardMultiplier += 100;
            emit CriticalRoundStarted(poolId, features.currentRound);
        }
        if(pool.players.length <= pool.winnerCount) {
            distributeRewards(poolId);
        }
    }

    function awardPoints(uint256 poolId, address player, uint256 amount) internal {
        poolFeatures[poolId].points[player] += amount;
        checkImmunityThreshold(poolId, player);
    }

    function checkImmunityThreshold(uint256 poolId, address player) internal {
        PoolFeatures storage pf = poolFeatures[poolId];
        if(pf.points[player] >= 100) {
            pf.points[player] -= 100;
            grantImmunity(poolId, player, 1 hours);
        }
    }

    function processCriticalRound(uint256 poolId) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        if(isInArray(features.criticalRounds, features.currentRound)) {
            increaseEliminationCount(poolId);
            features.rewardMultiplier += 100;
            for(uint256 i = 0; i < features.revivalPool.length; i++) {
                address player = features.revivalPool[i];
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
        for(uint256 i = 0; i < levelMultipliers.length && i < 4; i++) {
            pf.levelMultipliers[i+1] = levelMultipliers[i];
        }
    }

    function levelUp(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        uint256 currentLevel = features.playerLevel[player];
        require(currentLevel < 4, "Max level");
        uint256 requiredFee = pools[poolId].entranceFee * (currentLevel + 1);
        require(msg.value == requiredFee, "Incorrect fee");
        features.playerLevel[player]++;
        features.immunityCount[player] += currentLevel;
        if(currentLevel == 4) {
            markForBonusReward(poolId, player);
        }
    }

    function voteForNextElimination(uint256 poolId, uint256 timeChoice) external {
        require(timeChoice >= 1 && timeChoice <= 3, "Invalid choice");
        PoolFeatures storage features = poolFeatures[poolId];
        features.timeVotes[msg.sender] = timeChoice;
        updateEliminationTime(poolId);
    }

    function updateEliminationTime(uint256 poolId) internal {
        uint256[] memory times = new uint256[](3);
        times[0] = 1800;
        times[1] = 3600;
        times[2] = 7200;
        uint256 mostVotedIndex = calculateMostVotedTime(poolId);
        pools[poolId].eliminationInterval = times[mostVotedIndex];
    }

    function grantImmunity(uint256 poolId, address player, uint256 duration) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.immunityCount[player]++;
        features.immunityExpiry[player] = block.timestamp + duration;
        emit ImmunityGranted(poolId, player, duration);
    }

    function increaseEliminationCount(uint256 poolId) internal returns (uint256) {
        Pool storage pool = pools[poolId];
        if (isCriticalRound(poolId)) {
            pool.eliminationCount *= 2;
        }
        return pool.eliminationCount;
    }

    function increaseRewardMultiplier(uint256 poolId, uint256 amount) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.rewardMultiplier += amount;
        emit RewardMultiplierIncreased(poolId, amount);
    }

    function awardSurvivorBonus(uint256 poolId, address player) internal {
        uint256 bonus = calculateSurvivorBonus(poolId, player);
        rewards[poolId][player] += bonus;
        emit SurvivorBonusAwarded(poolId, player, bonus);
    }

    function activateSuddenDeath(uint256 poolId) internal {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        require(pool.players.length <= 5, "Too many");
        pool.eliminationInterval = 300;
        features.isSuddenDeathActive = true;
        emit SuddenDeathActivated(poolId);
    }

    function calculateMostVotedTime(uint256 poolId) internal view returns (uint256) {
        uint256[3] memory votes = [uint256(0), 0, 0];
        uint256[] memory times = new uint256[](3);
        times[0] = 1800;
        times[1] = 3600;
        times[2] = 7200;
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
        require(eliminatedPlayers[poolId].length >= 3, "Not enough");
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

    function applyBonuses(uint256 reward, PoolFeatures storage features) internal view returns (uint256) {
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

    function applyRiskMultipliers(uint256 reward, PoolFeatures storage features) internal view returns (uint256) {
        if (features.riskLevel[msg.sender] > 1) {
            reward += (reward * features.riskLevel[msg.sender] * 5) / 100;
        }
        return reward;
    }

    function setLevelMultiplier(uint256 poolId, uint256 level, uint256 multiplier) external onlyOwner {
        require(level > 0 && level <= 4, "Invalid level");
        require(multiplier > 0, "Invalid multiplier");
        poolFeatures[poolId].levelMultipliers[level] = multiplier;
        emit LevelMultiplierSet(poolId, level, multiplier);
    }

    function checkImmunityExpiry(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        if (features.hasImmunity[player] && block.timestamp >= features.immunityExpiry[player]) {
            features.hasImmunity[player] = false;
            emit ImmunityExpired(poolId, player);
        }
    }

    function advanceRound(uint256 poolId) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.currentRound++;
        emit RoundAdvanced(poolId, features.currentRound);
    }

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

    address public platformFeeAddress;
    
    function setPlatformFeeAddress(address _platformFeeAddress) external onlyOwner {
        require(_platformFeeAddress != address(0), "Zero address");
        platformFeeAddress = _platformFeeAddress;
    }
    
    function setPlatformFeePercentage(uint256 _platformFeePercentage) external onlyOwner {
        require(_platformFeePercentage <= 100, "Exceeds 100");
        PLATFORM_FEE_PERCENT = _platformFeePercentage;
    }
    
    function emergencyCompletePool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Inactive");
        pool.active = false;
        distributeRewards(poolId);
    }
    
    mapping(uint256 => bool) public pausedPools;
    
    function pausePool(uint256 poolId) external onlyOwner {
        require(pools[poolId].active, "Inactive");
        require(!pausedPools[poolId], "Already paused");
        pausedPools[poolId] = true;
    }
    
    function resumePool(uint256 poolId) external onlyOwner {
        require(pools[poolId].active, "Inactive");
        require(pausedPools[poolId], "Not paused");
        pausedPools[poolId] = false;
    }
    
    function updatePoolFeatures(uint256 poolId, uint256 features) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Inactive");
        if ((features & FEATURE_CHAIN_ELIMINATION) != 0) {
            require(pool.eliminationCount == 1, "Invalid count");
        }
        poolFeatures[poolId].activeFeatures = features;
    }
    
    function withdrawFunds(address recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0), "Zero address");
        require(address(this).balance >= amount, "Insufficient");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    function withdrawPlatformFee(uint256 poolId) external onlyOwner nonReentrant {
        Pool storage pool = pools[poolId];
        require(!pool.active, "Active");
        uint256 totalPoolAmount = pool.entranceFee * pool.players.length;
        uint256 platformFee = (totalPoolAmount * PLATFORM_FEE_PERCENT) / 100;
        address recipient = platformFeeAddress != address(0) ? platformFeeAddress : owner;
        (bool success, ) = payable(recipient).call{value: platformFee}("");
        require(success, "Transfer failed");
    }

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

    function totalBetsPlaced() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= poolCounter; i++) {
            total += bets[i].length;
        }
        return total;
    }
    
    function completePool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Inactive");
        distributeRewards(poolId);
    }

    function updateEntranceFee(uint256 poolId, uint256 newFee) external onlyOwner {
        require(pools[poolId].active, "Inactive");
        require(newFee > 0, "Zero fee");
        pools[poolId].entranceFee = newFee;
    }

    function updateTicketPrices(uint256 poolId, uint256 rescuePrice, uint256 healingPrice) external onlyOwner {
        require(pools[poolId].active, "Inactive");
        require(rescuePrice > 0, "Zero price");
        require(healingPrice > 0, "Zero price");
        PoolFeatures storage features = poolFeatures[poolId];
        features.rescueTicketPrice = rescuePrice;
        features.healingTicketPrice = healingPrice;
    }

    function updateRewardMultiplier(uint256 poolId, uint256 multiplier) external onlyOwner {
        require(pools[poolId].active, "Inactive");
        require(multiplier > 0, "Zero multiplier");
        poolFeatures[poolId].rewardMultiplier = multiplier;
        emit RewardMultiplierIncreased(poolId, multiplier);
    }

    function updateWinnerCount(uint256 poolId, uint256 newWinnerCount) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Inactive");
        require(newWinnerCount > 0, "Zero winner");
        require(newWinnerCount < pool.maxPlayers, "Exceeds max");
        pool.winnerCount = newWinnerCount;
    }

    function updateEliminationInterval(uint256 poolId, uint256 newInterval) external onlyOwner {
        require(pools[poolId].active, "Inactive");
        require(newInterval >= 300, "Too short");
        pools[poolId].eliminationInterval = newInterval;
    }

    function updateEliminationCount(uint256 poolId, uint256 newCount) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.active, "Inactive");
        require(newCount > 0, "Zero count");
        require(newCount < pool.players.length, "Exceeds players");
        if (poolFeatures[poolId].activeFeatures & FEATURE_CHAIN_ELIMINATION != 0) {
            require(newCount == 1, "Invalid count");
        }
        pool.eliminationCount = newCount;
    }

    function processBetWinners(uint256 poolId, address eliminatedPlayer) internal {
        for (uint256 i = 0; i < bets[poolId].length; i++) {
            Bet storage bet = bets[poolId][i];
            if (bet.guess == eliminatedPlayer) {
                uint256 multiplier = 2;
                Pool storage pool = pools[poolId];
                if (pool.betRule == BetRuleType.FirstThreeInOrder) multiplier = 3;
                else if (pool.betRule == BetRuleType.LastFiveAnyOrder) multiplier = 4;
                uint256[] memory activeBetTypes = poolBetTypes[poolId];
                for (uint256 j = 0; j < activeBetTypes.length; j++) {
                    uint256 betTypeId = activeBetTypes[j];
                    if (poolActiveBetTypes[poolId][betTypeId]) {
                        if (betTypeConfigs[betTypeId].multiplier > multiplier * 100) {
                            multiplier = betTypeConfigs[betTypeId].multiplier / 100;
                        }
                    }
                }
                uint256 reward = calculateBetReward(poolId, bet.amount, multiplier);
                rewards[poolId][bet.player] += reward;
                emit BetWon(poolId, bet.player, reward, eliminatedPlayer);
            }
        }
    }

    receive() external payable {}
    fallback() external payable {}
    
    function devSetupTestPool() external onlyOwner {
        createPool(
            1 ether,
            5,
            3600,
            1,
            3,
            FEATURE_CHAIN_ELIMINATION | FEATURE_CRITICAL_ROUNDS,
            0.1 ether,
            0.05 ether,
            120,
            200
        );
    }

    function testFullCycle() external onlyOwner {
        uint256 entranceFee = 1 ether;
        uint256 maxPlayers = 10;
        uint256 eliminationInterval = 3600;
        uint256 eliminationCount = 1;
        uint256 winnerCount = 3;
        uint256[] memory criticalRounds = new uint256[](2);
        criticalRounds[0] = 3;
        criticalRounds[1] = 6;
        uint256 features = FEATURE_CHAIN_ELIMINATION | FEATURE_CRITICAL_ROUNDS | FEATURE_LEVEL_SYSTEM | FEATURE_RISK_LEVELS | FEATURE_POINT_SYSTEM | FEATURE_SUDDEN_DEATH;
        createPool(
            entranceFee,
            maxPlayers,
            eliminationInterval,
            eliminationCount,
            winnerCount,
            features,
            0.1 ether,
            0.05 ether,
            120,
            200
        );
        createBetType("First 3 Order", "First three eliminations", 300, 10, 1, true, false);
    }

    function isEliminated(uint256 poolId, address player) internal view returns (bool) {
        for(uint256 i = 0; i < eliminatedPlayers[poolId].length; i++) {
            if(eliminatedPlayers[poolId][i] == player) return true;
        }
        return false;
    }

    function getEligiblePlayers(uint256 poolId) internal view returns (address[] memory) {
        Pool storage pool = pools[poolId];
        uint256 count = 0;
        for(uint256 i = 0; i < pool.players.length; i++) {
            if(!poolFeatures[poolId].hasImmunity[pool.players[i]]) count++;
        }
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

    function selectWeightedRandom(uint256 poolId, address[] memory players, uint256[] memory weights) internal view returns (address) {
        require(players.length == weights.length, "Length mismatch");
        require(players.length > 0, "Empty array");
        uint256 totalWeight = 0;
        for(uint256 i = 0; i < weights.length; i++) totalWeight += weights[i];
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, poolId))) % totalWeight;
        uint256 cumulativeWeight = 0;
        for(uint256 i = 0; i < weights.length; i++) {
            cumulativeWeight += weights[i];
            if(randomNumber < cumulativeWeight) return players[i];
        }
        return players[0];
    }

    function markAdjacentPlayersAtRisk(uint256 poolId, address player) internal {
        Pool storage pool = pools[poolId];
        uint256 playerIndex = 0;
        for(uint256 i = 0; i < pool.players.length; i++) {
            if(pool.players[i] == player) {
                playerIndex = i;
                break;
            }
        }
        if(playerIndex > 0) poolFeatures[poolId].isAtRisk[pool.players[playerIndex-1]] = true;
        if(playerIndex < pool.players.length-1) poolFeatures[poolId].isAtRisk[pool.players[playerIndex+1]] = true;
    }

    function isCriticalRound(uint256 poolId) internal view returns (bool) {
        return isInArray(poolFeatures[poolId].criticalRounds, poolFeatures[poolId].currentRound);
    }

    function calculateSurvivorBonus(uint256 poolId, address player) internal view returns (uint256) {
        Pool storage pool = pools[poolId];
        PoolFeatures storage features = poolFeatures[poolId];
        return pool.entranceFee * features.playerLevel[player] * features.rewardMultiplier / 100;
    }

    function markForBonusReward(uint256 poolId, address player) internal {
        PoolFeatures storage features = poolFeatures[poolId];
        features.hasBonusReward[player] = true;
        features.bonusAmount[player] = calculateBonusAmount(poolId, player);
        emit BonusRewardMarked(poolId, player);
    }
}