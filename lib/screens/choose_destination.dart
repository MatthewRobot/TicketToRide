import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/destination.dart';
import 'player_screen.dart';

class ChooseDestination extends StatefulWidget {
  final bool isInitialSelection;
  final int? playerIndex;

  const ChooseDestination({
    super.key,
    this.isInitialSelection = true,
    this.playerIndex,
  });

  @override
  State<ChooseDestination> createState() => _ChooseDestinationState();
}

class _ChooseDestinationState extends State<ChooseDestination> {
  List<Destination> _availableDestinations = [];
  List<Destination> _selectedDestinations = [];
  bool _isLoading = true;
  bool _hasSubmitted = false;
  bool _destinationsLoaded = false; // NEW: Track if we've loaded destinations

  @override
  void initState() {
    super.initState();
    print('=== ChooseDestination initState called ===');
    print('Widget hash: ${widget.hashCode}');
    print('State hash: ${hashCode}');
    _loadDestinations();
  }

  @override
  void didUpdateWidget(ChooseDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('=== ChooseDestination didUpdateWidget called ===');
    print('Old widget hash: ${oldWidget.hashCode}');
    print('New widget hash: ${widget.hashCode}');
    print('State hash: ${hashCode}');
    print('_destinationsLoaded: $_destinationsLoaded');
  }

  @override
  void dispose() {
    print('=== ChooseDestination dispose called ===');
    print('State hash: ${hashCode}');
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    if (_destinationsLoaded) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // 1. Get current player's pending destinations if they exist (re-opening the screen)
    // We assume you have a way to get the current player via gameProvider.
    final currentPlayer = gameProvider.players.firstWhere((p) =>
        p.userId ==
        gameProvider.userId); // Assuming currentUserId getter exists

    if (currentPlayer.hasPendingDestinations) {
      // Player already drew, just use the pending cards
      setState(() {
        _availableDestinations = currentPlayer.pendingDestinations;
        _isLoading = false;
        _destinationsLoaded = true;
      });
      return;
    }

    // 2. Otherwise, perform a new transactional draw
    try {
      final List<Destination> dealtCards = widget.isInitialSelection
          ? await gameProvider
              .getInitialDestinations() // Use transactional initial draw
          : await gameProvider
              .drawDestinations(); // Use transactional mid-game draw

      if (mounted) {
        setState(() {
          _availableDestinations = dealtCards;
          _isLoading = false;
          _destinationsLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading destinations: $e');
      final errorString = e.toString();
      
      if (errorString.contains("Player already has pending destinations") ||
          errorString.contains("It is not your turn")) {
        // This is a race condition. The correct state is likely being handled 
        // by the ChooseDestination screen being closed or the turn advancing.
        // We will just log and pop silently.
        print('INFO: Suppressing known race condition error: $errorString');
      } else {
        // A real error occurred.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error drawing destinations: $e')),
          );
        }
      }
      
      // Always pop on any failed draw to prevent being stuck.
      if (mounted) {
        Navigator.of(context).pop(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== ChooseDestination build called ===');
    print('State hash: ${hashCode}');
    print('_destinationsLoaded: $_destinationsLoaded');
    print('_availableDestinations.length: ${_availableDestinations.length}');

    final screenSize = MediaQuery.of(context).size;
    // Use listen: false to prevent rebuilds from Firebase
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // Determine which player is selecting
    final effectivePlayerIndex =
        widget.playerIndex ?? gameProvider.myPlayerIndex;

    if (effectivePlayerIndex == null ||
        effectivePlayerIndex >= gameProvider.players.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Player not found')),
      );
    }

    final player = gameProvider.players[effectivePlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} - Choose Destinations'),
        centerTitle: true,
        backgroundColor: player.color,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    widget.isInitialSelection
                        ? 'Choose destinations to keep (2-3 cards):'
                        : 'Choose destinations to keep (1-3 cards):',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = _availableDestinations[index];
                        final isSelected =
                            _selectedDestinations.contains(destination);
                        final canSelect =
                            _selectedDestinations.length < 3 || isSelected;

                        return Container(
                          margin:
                              EdgeInsets.only(bottom: screenSize.height * 0.01),
                          child: Card(
                            elevation: isSelected ? 8 : 2,
                            color: isSelected ? Colors.blue[100] : Colors.white,
                            child: ListTile(
                              onTap: canSelect
                                  ? () => _toggleSelection(destination)
                                  : null,
                              title: Text(
                                destination.displayName,
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.blue[800]
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                '${destination.points} points',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.035,
                                  color: isSelected
                                      ? Colors.blue[600]
                                      : Colors.grey[600],
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.blue[800],
                                      size: screenSize.width * 0.06,
                                    )
                                  : Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey[400],
                                      size: screenSize.width * 0.06,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Container(
                    padding: EdgeInsets.all(screenSize.width * 0.03),
                    decoration: BoxDecoration(
                      color:
                          _canSubmit() ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Selected: ${_selectedDestinations.length}/3',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenSize.height * 0.005),
                        Text(
                          widget.isInitialSelection
                              ? 'Keep 2-3 cards'
                              : 'Keep 1-3 cards',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.03,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  ElevatedButton(
                    onPressed: _canSubmit() && !_hasSubmitted ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _hasSubmitted ? 'Submitting...' : 'Submit Selection',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                ],
              ),
            ),
    );
  }

  void _toggleSelection(Destination destination) {
    setState(() {
      if (_selectedDestinations.contains(destination)) {
        _selectedDestinations.remove(destination);
      } else {
        if (_selectedDestinations.length < 3) {
          _selectedDestinations.add(destination);
        }
      }
    });
  }

  bool _canSubmit() {
    if (widget.isInitialSelection) {
      return _selectedDestinations.length >= 2 &&
          _selectedDestinations.length <= 3;
    } else {
      return _selectedDestinations.length >= 1 &&
          _selectedDestinations.length <= 3;
    }
  }

  // In choose_destination.dart

void _submit() async {
    if (!_canSubmit() || _hasSubmitted) return;

    setState(() {
      _hasSubmitted = true;
    });

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final effectivePlayerIndex =
        widget.playerIndex ?? gameProvider.myPlayerIndex;

    if (effectivePlayerIndex == null ||
        effectivePlayerIndex >= gameProvider.players.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Player identity lost. Please rejoin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final player = gameProvider.players[effectivePlayerIndex];

    // Cards that were not selected go back to used pile
    final unselectedDestinations = _availableDestinations
        .where((d) => !_selectedDestinations.contains(d))
        .toList();

    try {
      // Determine the endTurn flag: 
      // Initial selection (true) should NOT end the turn (endTurn: false)
      // Mid-game draw (false) SHOULD end the draw phase (endTurn: true)
      final shouldEndTurn = !widget.isInitialSelection;

      // Call the GameProvider method ONCE with the correct flag.
      // This handles saving to Firebase, updating local state, and calling nextTurn() if shouldEndTurn is true.
      await gameProvider.completeDestinationSelection(
          player, _selectedDestinations, unselectedDestinations,
          endTurn: shouldEndTurn); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected ${_selectedDestinations.length} destination(s)',
            ),
          ),
        );

        if (widget.isInitialSelection) {
          // Initial Selection: Navigate to PlayerScreen without ending the turn.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                playerIndex: effectivePlayerIndex,
              ),
            ),
            (route) => false,
          );
        } else {
          // Mid-game: Pop back to the main game screen (turn advanced in GameProvider).
          Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/PlayerScreen');
        }
      }
    } catch (e) {
      print('Error submitting destinations: $e');
      if (mounted) {
        setState(() {
          _hasSubmitted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
}
}
