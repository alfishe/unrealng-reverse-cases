# Rooms

`room-NN.txt`: room NN's map (RoomNNMap, `$7600 + 240 x NN`), 5 rows of 48 block numbers in hex, the six screens of 8
blocks side by side. A block number indexes `blocks/blocks.txt`. Lines starting with # are comments.

`python3 tools/roommap.py --res OUT` draws every room (`OUT/room-NN.png`) and the world map (`OUT/world.png`, every
room with its zone, exits and enemy kinds) from these files, `blocks/`, `charsets/` and `tables/rooms.csv`.
