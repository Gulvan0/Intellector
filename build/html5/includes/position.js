self.onmessage = function(e) {
    if (e.data.command == "bestMoveByLevel")
    {
        let p = new Position(e.data.position);
        let res = p.bestMoveByLevel(e.data.level);
        self.postMessage(res);
    }
    if (e.data.command == "bestMoveByTime")
    {
        let p = new Position(e.data.position);
        let res = p.bestMoveByTime(e.data.time);
        res.completed = true;
        self.postMessage(res);
    }
  }

global = this;

function getMaxOfArray(numArray) {
    return Math.max.apply(null, numArray);
}

function getMinOfArray(numArray) {
    return Math.min.apply(null, numArray);
}

function getColor(f) {
    return f % 2;
}

function changeRegister(f) {
    if (f % 2 === 0) return f + 1;
    return f - 1;
}

function cton(c) {
    switch (c) {
        case 'a1': return 0;
        case 'a2': return 1;
        case 'a3': return 2;
        case 'a4': return 3;
        case 'a5': return 4;
        case 'a6': return 5;
        case 'a7': return 6;

        case 'b1': return 7;
        case 'b2': return 8;
        case 'b3': return 9;
        case 'b4': return 10;
        case 'b5': return 11;
        case 'b6': return 12;

        case 'c1': return 13;
        case 'c2': return 14;
        case 'c3': return 15;
        case 'c4': return 16;
        case 'c5': return 17;
        case 'c6': return 18;
        case 'c7': return 19;
        
        case 'd1': return 20;
        case 'd2': return 21;
        case 'd3': return 22;
        case 'd4': return 23;
        case 'd5': return 24;
        case 'd6': return 25;

        case 'e1': return 26;
        case 'e2': return 27;
        case 'e3': return 28;
        case 'e4': return 29;
        case 'e5': return 30;
        case 'e6': return 31;
        case 'e7': return 32;

        case 'f1': return 33;
        case 'f2': return 34;
        case 'f3': return 35;
        case 'f4': return 36;
        case 'f5': return 37;
        case 'f6': return 38;

        case 'g1': return 39;
        case 'g2': return 40;
        case 'g3': return 41;
        case 'g4': return 42;
        case 'g5': return 43;
        case 'g6': return 44;
        case 'g7': return 45;

        case 'h1': return 46;
        case 'h2': return 47;
        case 'h3': return 48;
        case 'h4': return 49;
        case 'h5': return 50;
        case 'h6': return 51;

        case 'i1': return 52;
        case 'i2': return 53;
        case 'i3': return 54;
        case 'i4': return 55;
        case 'i5': return 56;
        case 'i6': return 57;
        case 'i7': return 58;
    }
}

function ntoc(n) {
    switch (n) {
        case 0: return 'a1';
        case 1: return 'a2';
        case 2: return 'a3';
        case 3: return 'a4';
        case 4: return 'a5';
        case 5: return 'a6';
        case 6: return 'a7';

        case 7: return 'b1';
        case 8: return 'b2';
        case 9: return 'b3';
        case 10: return 'b4';
        case 11: return 'b5';
        case 12: return 'b6';
        
        case 13: return 'c1';
        case 14: return 'c2';
        case 15: return 'c3';
        case 16: return 'c4';
        case 17: return 'c5';
        case 18: return 'c6';
        case 19: return 'c7';

        case 20: return 'd1';
        case 21: return 'd2';
        case 22: return 'd3';
        case 23: return 'd4';
        case 24: return 'd5';
        case 25: return 'd6';
        
        case 26: return 'e1';
        case 27: return 'e2';
        case 28: return 'e3';
        case 29: return 'e4';
        case 30: return 'e5';
        case 31: return 'e6';
        case 32: return 'e7';

        case 33: return 'f1';
        case 34: return 'f2';
        case 35: return 'f3';
        case 36: return 'f4';
        case 37: return 'f5';
        case 38: return 'f6';
        
        case 39: return 'g1';
        case 40: return 'g2';
        case 41: return 'g3';
        case 42: return 'g4';
        case 43: return 'g5';
        case 44: return 'g6';
        case 45: return 'g7';

        case 46: return 'h1';
        case 47: return 'h2';
        case 48: return 'h3';
        case 49: return 'h4';
        case 50: return 'h5';
        case 51: return 'h6';
        
        case 52: return 'i1';
        case 53: return 'i2';
        case 54: return 'i3';
        case 55: return 'i4';
        case 56: return 'i5';
        case 57: return 'i6';
        case 58: return 'i7';
    } 
}

function fton(f) {
    switch (f) {
        case 'p': return 0;
        case 'm': return 2;
        case 'l': return 4;
        case 'a': return 6;
        case 'd': return 8;
        case 'i': return 10;

        case 'P': return 1;
        case 'M': return 3;
        case 'L': return 5;
        case 'A': return 7;
        case 'D': return 9;
        case 'I': return 11;

        case 'e': return 12;

        case 'v': return 13;
    }
}

function ntof(n) {
    switch (n) {
        case 0: return 'p';
        case 2: return 'm';
        case 4: return 'l';
        case 6: return 'a';
        case 8: return 'd';
        case 10: return 'i';

        case 1: return 'P';
        case 3: return 'M';
        case 5: return 'L';
        case 7: return 'A';
        case 9: return 'D';
        case 11: return 'I';

        case 12: return 'e';

        case 13: return 'v';
    }
}

function oton(o) {
    if (o === 'w') return 0;
    return 1;
}

function ntoo(n) {
    if (n === 0) return 'w';
    return 'b';
}

const ε = 1;

const coords = [
    'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7',
    'b1', 'b2', 'b3', 'b4', 'b5', 'b6',
    'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7',
    'd1', 'd2', 'd3', 'd4', 'd5', 'd6',
    'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7',
    'f1', 'f2', 'f3', 'f4', 'f5', 'f6',
    'g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'i1', 'i2', 'i3', 'i4', 'i5', 'i6', 'i7',
];
const figures = ['p', 'm', 'l', 'a', 'd', 'i', 'P', 'M', 'L', 'A', 'D', 'I'];
const marks = [100, -100, 600, -600, 170, -170, 200, -200, 150, -150, 100000, -100000, 0];

const mMoves = [
    /*a1: */[
            [1, 2, 3, 4, 5, 6],
            [7, 14, 21, 28, 35, 42, 49, 56],
            [],
            [],
            [],
            [],
    ],
        
    /*a2: */[
            [2, 3, 4, 5, 6],
            [8, 15, 22, 29, 36, 43, 50, 57],
            [7, 13],
            [0],
            [],
            [],
    ],

    /*a3: */[
            [3, 4, 5, 6],
            [9, 16, 23, 30, 37, 44, 51, 58],
            [8, 14, 20, 26],
            [1, 0],
            [],
            [],
    ],

    /*a4: */[
            [4, 5, 6],
            [10, 17, 24, 31, 38, 45],
            [9, 15, 21, 27, 33, 39],
            [2, 1, 0],
            [],
            [],
    ],

    /*a5: */[
            [5, 6],
            [11, 18, 25, 32],
            [10, 16, 22, 28, 34, 40, 46, 52],
            [3, 2, 1, 0],
            [],
            [],
    ],

    /*a6: */[
            [6],
            [12, 19],
            [11, 17, 23, 29, 35, 41, 47, 53],
            [4, 3, 2, 1, 0],
            [],
            [],
    ],

    /*a7: */[
            [],
            [],
            [12, 18, 24, 30, 36, 42, 48, 54],
            [5, 4, 3, 2, 1, 0],
            [],
            [],
    ],

    /*b1: */[
            [8, 9, 10, 11, 12],
            [14, 21, 28, 35, 42, 49, 56],
            [13],
            [],
            [0],
            [1],
    ],

    /*b2: */[
            [9, 10, 11, 12],
            [15, 22, 29, 36, 43, 50, 57],
            [14, 20, 26],
            [7],
            [1],
            [2],
    ],

    /*b3: */[
            [10, 11, 12],
            [16, 23, 30, 37, 44, 51, 58],
            [15, 21, 27, 33, 39],
            [8, 7],
            [2],
            [3],
    ],

    /*b4: */[
            [11, 12],
            [17, 24, 31, 38, 45],
            [16, 22, 28, 34, 40, 46, 52],
            [9, 8, 7],
            [3],
            [4],
    ],

    /*b5: */[
            [12],
            [18, 25, 32],
            [17, 23, 29, 35, 41, 47, 53],
            [10, 9, 8, 7],
            [4],
            [5],
    ],

    /*b6: */[
            [],
            [19],
            [18, 24, 30, 36, 42, 48, 54],
            [11, 10, 9, 8, 7],
            [5],
            [6],
    ],

    /*c1: */[
            [14, 15, 16, 17, 18, 19],
            [20, 27, 34, 41, 48, 55],
            [],
            [],
            [],
            [7, 1],
    ],

    /*c2: */[
            [15, 16, 17, 18, 19],
            [21, 28, 35, 42, 49, 56],
            [20, 26],
            [13],
            [7, 0],
            [8, 2],
    ],

    /*c3: */[
            [16, 17, 18, 19],
            [22, 29, 36, 43, 50, 57],
            [21, 27, 33, 39],
            [14, 13],
            [8, 1],
            [9, 3],
    ],

    /*c4: */[
            [17, 18, 19],
            [23, 30, 37, 44, 51, 58],
            [22, 28, 34, 40, 46, 52],
            [15, 14, 13],
            [9, 2],
            [10, 4],
    ],

    /*c5: */[
            [18, 19],
            [24, 31, 38, 45],
            [23, 29, 35, 41, 47, 53],
            [16, 15, 14, 13],
            [10, 3],
            [11, 5],
    ],

    /*c6: */[
            [19],
            [25, 32],
            [24, 30, 36, 42, 48, 54],
            [17, 16, 15, 14, 13],
            [11, 4],
            [12, 6],
    ],

    /*c7: */[
            [],
            [],
            [25, 31, 37, 43, 49, 55],
            [18, 17, 16, 15, 14, 13],
            [12, 5],
            [],
    ],

    /*d1: */[
            [21, 22, 23, 24, 25],
            [27, 34, 41, 48, 55],
            [26],
            [],
            [13],
            [14, 8, 2],
    ],

    /*d2: */[
            [22, 23, 24, 25],
            [28, 35, 42, 49, 56],
            [27, 33, 39],
            [20],
            [14, 7, 0],
            [15, 9, 3],
    ],

    /*d3: */[
            [23, 24, 25],
            [29, 36, 43, 50, 57],
            [28, 34, 40, 46, 52],
            [21, 20],
            [15, 8, 1],
            [16, 10, 4],
    ],

    /*d4: */[
            [24, 25],
            [30, 37, 44, 51, 58],
            [29, 35, 41, 47, 53],
            [22, 21, 20],
            [16, 9, 2],
            [17, 11, 5],
    ],

    /*d5: */[
            [25],
            [31, 38, 45],
            [30, 36, 42, 48, 54],
            [23, 22, 21, 20],
            [17, 10, 3],
            [18, 12, 6],
    ],

    /*d6: */[
            [],
            [32],
            [31, 37, 43, 49, 55],
            [24, 23, 22, 21, 20],
            [18, 11, 4],
            [19],
    ],

    /*e1: */[
            [27, 28, 29, 30, 31, 32],
            [33, 40, 47, 54],
            [],
            [],
            [],
            [20, 14, 8, 2],
    ],

    /*e2: */[
            [28, 29, 30, 31, 32],
            [34, 41, 48, 55],
            [33, 39],
            [26],
            [20, 13],
            [21, 15, 9, 3],
    ],

    /*e3: */[
            [29, 30, 31, 32],
            [35, 42, 49, 56],
            [34, 40, 46, 52],
            [27, 26],
            [21, 14, 7, 0],
            [22, 16, 10, 4],
    ],

    /*e4: */[
            [30, 31, 32],
            [36, 43, 50, 57],
            [35, 41, 47, 53],
            [28, 27, 26],
            [22, 15, 8, 1],
            [23, 17, 11, 5],
    ],

    /*e5: */[
            [31, 32],
            [37, 44, 51, 58],
            [36, 42, 48, 54],
            [29, 28, 27, 26],
            [23, 16, 9, 2],
            [24, 18, 12, 6],
    ],

    /*e6: */[
            [32],
            [38, 45],
            [37, 43, 49, 55],
            [30, 29, 28, 27, 26],
            [24, 17, 10, 3],
            [25, 19],
    ],

    /*e7: */[
            [],
            [],
            [38, 44, 50, 56],
            [31, 30, 29, 28, 27, 26],
            [25, 18, 11, 4],
            [],
    ],

    /*f1: */[
            [34, 35, 36, 37, 38],
            [40, 47, 54],
            [39],
            [],
            [26],
            [27, 21, 15, 9, 3],
    ],

    /*f2: */[
            [35, 36, 37, 38],
            [41, 48, 55],
            [40, 46, 52],
            [33],
            [27, 20, 13],
            [28, 22, 16, 10, 4],
    ],

    /*f3: */[
            [36, 37, 38],
            [42, 49, 56],
            [41, 47, 53],
            [34, 33],
            [28, 21, 14, 7, 0],
            [29, 23, 17, 11, 5],
    ],

    /*f4: */[
            [37, 38],
            [43, 50, 57],
            [42, 48, 54],
            [35, 34, 33],
            [29, 22, 15, 8, 1],
            [30, 24, 18, 12, 6],
    ],

    /*f5: */[
            [38],
            [44, 51, 58],
            [43, 49, 55],
            [36, 35, 34, 33],
            [30, 23, 16, 9, 2],
            [31, 25, 19],
    ],

    /*f6: */[
            [],
            [45],
            [44, 50, 56],
            [37, 36, 35, 34, 33],
            [31, 24, 17, 10, 3],
            [32],
    ],

    /*g1: */[
            [40, 41, 42, 43, 44, 45],
            [46, 53],
            [],
            [],
            [],
            [33, 27, 21, 15, 9, 3],
    ],

    /*g2: */[
            [41, 42, 43, 44, 45],
            [47, 54],
            [46, 52],
            [39],
            [33, 26],
            [34, 28, 22, 16, 10, 4],
    ],

    /*g3: */[
            [42, 43, 44, 45],
            [48, 55],
            [47, 53],
            [40, 39],
            [34, 27, 20, 13],
            [35, 29, 23, 17, 11, 5],
    ],

    /*g4: */[
            [43, 44, 45],
            [49, 56],
            [48, 54],
            [41, 40, 39],
            [35, 28, 21, 14, 7, 0],
            [36, 30, 24, 18, 12, 6],
    ],

    /*g5: */[
            [44, 45],
            [50, 57],
            [49, 55],
            [42, 41, 40, 39],
            [36, 29, 22, 15, 8, 1],
            [37, 31, 25, 19],
    ],

    /*g6: */[
            [45],
            [51, 58],
            [50, 56],
            [43, 42, 41, 40, 39],
            [37, 30, 23, 16, 9, 2],
            [38, 32],
    ],

    /*g7: */[
            [],
            [],
            [51, 57],
            [44, 43, 42, 41, 40, 39],
            [38, 31, 24, 17, 10, 3],
            [],
    ],

    /*h1: */[
            [47, 48, 49, 50, 51],
            [53],
            [52],
            [],
            [39],
            [40, 34, 28, 22, 16, 10, 4],
    ],

    /*h2: */[
            [48, 49, 50, 51],
            [54],
            [53],
            [46],
            [40, 33, 26],
            [41, 35, 29, 23, 17, 11, 5],
    ],

    /*h3: */[
            [49, 50, 51],
            [55],
            [54],
            [47, 46],
            [41, 34, 27, 20, 13],
            [42, 36, 30, 24, 18, 12, 6],
    ],

    /*h4: */[
            [50, 51],
            [56],
            [55],
            [48, 47, 46],
            [42, 35, 28, 21, 14, 7, 0],
            [43, 37, 31, 25, 19],
    ],

    /*h5: */[
            [51],
            [57],
            [56],
            [49, 48, 47, 46],
            [43, 36, 29, 22, 15, 8, 1],
            [44, 38, 32],
    ],
    
    /*h6: */[
            [],
            [58],
            [57],
            [50, 49, 48, 47, 46],
            [44, 37, 30, 23, 16, 9, 2],
            [45],
    ],
    
    /*i1: */[
            [53, 54, 55, 56, 57, 58],
            [],
            [],
            [],
            [],
            [46, 40, 34, 28, 22, 16, 10, 4],
    ],

    /*i2: */[
            [54, 55, 56, 57, 58],
            [],
            [],
            [52],
            [46, 39],
            [47, 41, 35, 29, 23, 17, 11, 5],
    ], 

    /*i3: */[
            [55, 56, 57, 58],
            [],
            [],
            [53, 52],
            [47, 40, 33, 26],
            [48, 42, 36, 30, 24, 18, 12, 6],
    ],

    /*i4: */[
            [56, 57, 58],
            [],
            [],
            [54, 53, 52],
            [48, 41, 34, 27, 20, 13],
            [49, 43, 37, 31, 25, 19],
    ], 

    /*i5: */[
            [57, 58],
            [],
            [],
            [55, 54, 53, 52],
            [49, 42, 35, 28, 21, 14, 7, 0],
            [50, 44, 38, 32],
    ], 

    /*i6: */[
            [58],
            [],
            [],
            [56, 55, 54, 53, 52],
            [50, 43, 36, 29, 22, 15, 8, 1],
            [51, 45],
    ], 

    /*i7: */[
            [],
            [],
            [],
            [57, 56, 55, 54, 53, 52],
            [51, 44, 37, 30, 23, 16, 9, 2],
            [],
    ], 
];

const aMoves = [
    /*a1: */[
            [8, 16, 24, 32],
            [13, 26, 39, 52],
            [],
            [],
            [],
            [],
    ],

    /*a2: */[[], [], [], [], [], []],
    /*a3: */[[], [], [], [], [], []],
    
    /*a4: */[
            [11, 19],
            [16, 29, 42, 55],
            [8, 13],
            [],
            [],
            [],
    ],

    /*a5: */[[], [], [], [], [], []],
    /*a6: */[[], [], [], [], [], []],

    /*a7: */[
            [],
            [19, 32, 45, 58],
            [11, 16, 21, 26],
            [],
            [],
            [],
    ],

    /*b1: */[[], [], [], [], [], []],

    /*b2: */[
            [16, 24, 32],
            [21, 34, 47],
            [13],
            [0],
            [],
            [3],
    ],

    /*b3: */[[], [], [], [], [], []],
    /*b4: */[[], [], [], [], [], []],

    /*b5: */[
            [19],
            [24, 37, 50],
            [16, 21, 26],
            [3],
            [],
            [6],
    ],

    /*b6: */[[], [], [], [], [], []],

    /*c1: */[
            [21, 29, 37, 45],
            [26, 39, 52],
            [],
            [],
            [0],
            [8, 3],
    ],

    /*c2: */[[], [], [], [], [], []],
    /*c3: */[[], [], [], [], [], []], 

    /*c4: */[
            [24, 32],
            [29, 42, 55],
            [21, 26],
            [8, 0],
            [3],
            [11, 6],
    ],

    /*c5: */[[], [], [], [], [], []],
    /*c6: */[[], [], [], [], [], []],

    /*c7: */[
            [],
            [32, 45, 58],
            [24, 29, 34, 39],
            [11, 3],
            [6],
            [],
    ],

    /*d1: */[[], [], [], [], [], []],

    /*d2: */[
            [29, 37, 45],
            [34, 47],
            [26],
            [13],
            [8],
            [16, 11, 6],
    ],

    /*d3: */[[], [], [], [], [], []],
    /*d4: */[[], [], [], [], [], []],

    /*d5: */[
            [32],
            [37, 50],
            [29, 34, 39],
            [16, 8, 0],
            [11],
            [19],
    ],

    /*d6: */[[], [], [], [], [], []],

    /*e1: */[
            [34, 42, 50, 58],
            [39, 52],
            [],
            [],
            [13, 0],
            [21, 16, 11, 6],
    ],

    /*e2: */[[], [], [], [], [], []],
    /*e3: */[[], [], [], [], [], []],

    /*e4: */[
            [37, 45],
            [42, 55],
            [34, 39],
            [21, 13],
            [16, 3],
            [24, 19],
    ],

    /*e5: */[[], [], [], [], [], []],
    /*e6: */[[], [], [], [], [], []],

    /*e7: */[
            [],
            [45, 58],
            [37, 42, 47, 52],
            [24, 16, 8, 0],
            [19, 6],
            [],
    ],

    /*f1: */[[], [], [], [], [], []],

    /*f2: */[
            [42, 50, 58],
            [47],
            [39],
            [26],
            [21, 8],
            [29, 24, 19],
    ],

    /*f3: */[[], [], [], [], [], []],
    /*f4: */[[], [], [], [], [], []], 

    /*f5: */[
            [45],
            [50],
            [42, 47, 52],
            [29, 21, 13],
            [24, 11],
            [32],
    ],

    /*f6: */[[], [], [], [], [], []],

    /*g1: */[
            [47, 55],
            [52],
            [],
            [],
            [26, 13, 0],
            [34, 29, 24, 19],
    ],

    /*g2: */[[], [], [], [], [], []],
    /*g3: */[[], [], [], [], [], []],

    /*g4: */[
            [50, 58],
            [55],
            [47, 52],
            [34, 26],
            [29, 16, 3],
            [37, 32],
    ],

    /*g5: */[[], [], [], [], [], []],
    /*g6: */[[], [], [], [], [], []],

    /*g7: */[
            [],
            [58],
            [50, 55],
            [37, 29, 21, 13],
            [32, 19, 6],
            [],
    ],

    /*h1: */[[], [], [], [], [], []],

    /*h2: */[
            [55],
            [],
            [52],
            [39],
            [34, 21, 8],
            [42, 37, 32],
    ],

    /*h3: */[[], [], [], [], [], []],
    /*h4: */[[], [], [], [], [], []],

    /*h5: */[
            [58],
            [],
            [55],
            [42, 34, 26],
            [37, 24, 11],
            [45],
    ],

    /*h6: */[[], [], [], [], [], []],

    /*i1: */[
            [],
            [],
            [],
            [],
            [39, 26, 13, 0],
            [47, 42, 37, 32],
    ],

    /*i2: */[[], [], [], [], [], []],
    /*i3: */[[], [], [], [], [], []],

    /*i4: */[
            [],
            [],
            [],
            [47, 39],
            [42, 29, 16, 3],
            [50, 45],
    ],

    /*i5: */[[], [], [], [], [], []],
    /*i6: */[[], [], [], [], [], []],

    /*i7: */[
            [],
            [],
            [],
            [50, 42, 34, 26],
            [45, 32, 19, 6],
            [],
    ],
];

const lLongMoves = [
    /*a1: */[2, 14],
    /*a2: */[3, 15, 13],
    /*a3: */[4, 16, 14, 0],
    /*a4: */[5, 17, 15, 1],
    /*a5: */[6, 18, 16, 2],
    /*a6: */[19, 17, 3],
    /*a7: */[18, 4],

    /*b1: */[9, 21],
    /*b2: */[10, 22, 20],
    /*b3: */[11, 23, 21, 7],
    /*b4: */[12, 24, 22, 8],
    /*b5: */[25, 23, 9],
    /*b6: */[24, 10],

    /*c1: */[15, 27, 1],
    /*c2: */[16, 28, 26, 0, 2],
    /*c3: */[17, 29, 27, 13, 1, 3],
    /*c4: */[18, 30, 28, 14, 2, 4],
    /*c5: */[31, 29, 15, 3, 5, 19],
    /*c6: */[32, 30, 16, 4, 6],
    /*c7: */[31, 17, 5],

    /*d1: */[22, 34, 8],
    /*d2: */[23, 35, 33, 7, 9],
    /*d3: */[24, 36, 34, 20, 8, 10],
    /*d4: */[25, 37, 35, 21, 9, 11],
    /*d5: */[38, 36, 22, 10, 12],
    /*d6: */[37, 23, 11],

    /*e1: */[28, 40, 14],
    /*e2: */[29, 41, 39, 13, 15],
    /*e3: */[30, 42, 40, 26, 14, 16],
    /*e4: */[31, 43, 41, 27, 15, 17],
    /*e5: */[32, 44, 42, 28, 16, 18],
    /*e6: */[45, 43, 29, 17, 19],
    /*e7: */[44, 30, 18],

    /*f1: */[35, 47, 21],
    /*f2: */[36, 48, 46, 20, 22],
    /*f3: */[37, 49, 47, 33, 21, 23],
    /*f4: */[38, 50, 48, 34, 22, 24],
    /*f5: */[51, 49, 35, 23, 25],
    /*f6: */[50, 36, 24],

    /*g1: */[41, 53, 27],
    /*g2: */[42, 54, 52, 26, 28],
    /*g3: */[43, 55, 53, 39, 27, 29],
    /*g4: */[44, 56, 54, 40, 28, 30],
    /*g5: */[45, 57, 55, 41, 29, 31],
    /*g6: */[58, 56, 42, 30, 32],
    /*g7: */[57, 43, 31],

    /*h1: */[48, 34],
    /*h2: */[49, 33, 35],
    /*h3: */[50, 46, 34, 36],
    /*h4: */[51, 47, 35, 37],
    /*h5: */[48, 36, 38],
    /*h6: */[49, 37],

    /*i1: */[54, 40],
    /*i2: */[55, 39, 41],
    /*i3: */[56, 52, 40, 42],
    /*i4: */[57, 53, 41, 43],
    /*i5: */[58, 54, 42, 44],
    /*i6: */[55, 43, 45],
    /*i7: */[56, 44],
];

const lShortMoves = [
    /*a1: */[1, 7],
    /*a2: */[2, 8, 7, 0],
    /*a3: */[3, 9, 8, 1],
    /*a4: */[4, 10, 9, 2],
    /*a5: */[5, 11, 10, 3],
    /*a6: */[6, 12, 11, 4],
    /*a7: */[12, 5],

    /*b1: */[8, 14, 13, 0, 1],
    /*b2: */[9, 15, 14, 7, 1, 2],
    /*b3: */[10, 16, 15, 8, 2, 3],
    /*b4: */[11, 17, 16, 9, 3, 4],
    /*b5: */[12, 18, 17, 10, 4, 5],
    /*b6: */[19, 18, 11, 5, 6],

    /*c1: */[14, 20, 7],
    /*c2: */[15, 21, 20, 13, 7, 8],
    /*c3: */[16, 22, 21, 14, 8, 9],
    /*c4: */[17, 23, 22, 15, 9, 10],
    /*c5: */[18, 24, 23, 16, 10, 11],
    /*c6: */[19, 25, 24, 17, 11, 12],
    /*c7: */[25, 18, 12],

    /*d1: */[21, 27, 26, 13, 14],
    /*d2: */[22, 28, 27, 20, 14, 15],
    /*d3: */[23, 29, 28, 21, 15, 16],
    /*d4: */[24, 30, 29, 22, 16, 17],
    /*d5: */[25, 31, 30, 23, 17, 18],
    /*d6: */[32, 31, 24, 18, 19],

    /*e1: */[27, 33, 20],
    /*e2: */[28, 34, 33, 26, 20, 21],
    /*e3: */[29, 35, 34, 27, 21, 22],
    /*e4: */[30, 36, 35, 28, 22, 23],
    /*e5: */[31, 37, 36, 29, 23, 24],
    /*e6: */[32, 38, 37, 30, 24, 25],
    /*e7: */[38, 31, 25],

    /*f1: */[34, 40, 39, 26, 27],
    /*f2: */[35, 41, 40, 33, 27, 28],
    /*f3: */[36, 42, 41, 34, 28, 29],
    /*f4: */[37, 43, 42, 35, 29, 30],
    /*f5: */[38, 44, 43, 36, 30, 31],
    /*f6: */[45, 44, 37, 31, 32],

    /*g1: */[40, 46, 33],
    /*g2: */[41, 47, 46, 39, 33, 34],
    /*g3: */[42, 48, 47, 40, 34, 35],
    /*g4: */[43, 49, 48, 41, 35, 36],
    /*g5: */[44, 50, 49, 42, 36, 37],
    /*g6: */[45, 51, 50, 43, 37, 38],
    /*g7: */[51, 44, 38],

    /*h1: */[47, 53, 52, 39, 40],
    /*h2: */[48, 54, 53, 46, 40, 41],
    /*h3: */[49, 55, 54, 47, 41, 42],
    /*h4: */[50, 56, 55, 48, 42, 43],
    /*h5: */[51, 57, 56, 49, 43, 44],
    /*h6: */[58, 57, 50, 44, 45],

    /*i1: */[53, 46],
    /*i2: */[54, 52, 46, 47],
    /*i3: */[55, 53, 47, 48],
    /*i4: */[56, 54, 48, 49],
    /*i5: */[57, 55, 49, 50],
    /*i6: */[58, 56, 50, 51],
    /*i7: */[57, 51],
];

const iMoves = lShortMoves;
const dMoves = lShortMoves;
const near = lShortMoves;

const pMoves = [
    /*a1: */[],
    /*a2: */[2, 8],
    /*a3: */[3, 9],
    /*a4: */[4, 10],
    /*a5: */[5, 11],
    /*a6: */[6, 12],
    /*a7: */[cton('')],

    /*b1: */[1, 8, 14],
    /*b2: */[2, 9, 15],
    /*b3: */[3, 10, 16],
    /*b4: */[4, 11, 17],
    /*b5: */[5, 12, 18],
    /*b6: */[6, 19],

    /*c1: */[],
    /*c2: */[8, 15, 21],
    /*c3: */[9, 16, 22],
    /*c4: */[10, 17, 23],
    /*c5: */[11, 18, 24],
    /*c6: */[12, 19, 25],
    /*c7: */[],

    /*d1: */[14, 21, 27],
    /*d2: */[15, 22, 28],
    /*d3: */[16, 23, 29],
    /*d4: */[17, 24, 30],
    /*d5: */[18, 25, 31],
    /*d6: */[19, 32],

    /*e1: */[],
    /*e2: */[21, 28, 34],
    /*e3: */[22, 29, 35],
    /*e4: */[23, 30, 36],
    /*e5: */[24, 31, 37],
    /*e6: */[25, 32, 38],
    /*e7: */[],

    /*f1: */[27, 34, 40],
    /*f2: */[28, 35, 41],
    /*f3: */[29, 36, 42],
    /*f4: */[30, 37, 43],
    /*f5: */[31, 38, 44],
    /*f6: */[32, 45],

    /*g1: */[],
    /*g2: */[34, 41, 47],
    /*g3: */[35, 42, 48],
    /*g4: */[36, 43, 49],
    /*g5: */[37, 44, 50],
    /*g6: */[38, 45, 51],
    /*g7: */[],

    /*h1: */[40, 47, 53],
    /*h2: */[41, 48, 54],
    /*h3: */[42, 49, 55],
    /*h4: */[43, 50, 56],
    /*h5: */[44, 51, 57],
    /*h6: */[45, 58],

    /*i1: */[],
    /*i2: */[47, 54],
    /*i3: */[48, 55],
    /*i4: */[49, 56],
    /*i5: */[50, 57],
    /*i6: */[51, 58],
    /*i7: */[],
];

const PMoves = [
    /*a1: */[],
    /*a2: */[0, 7],
    /*a3: */[1, 8],
    /*a4: */[2, 9],
    /*a5: */[3, 10],
    /*a6: */[4, 11],
    /*a7: */[],

    /*b1: */[0, 13],
    /*b2: */[1, 7, 14],
    /*b3: */[2, 8, 15],
    /*b4: */[3, 9, 16],
    /*b5: */[4, 10, 17],
    /*b6: */[5, 11, 18],

    /*c1: */[],
    /*c2: */[7, 13, 20],
    /*c3: */[8, 14, 21],
    /*c4: */[9, 15, 22],
    /*c5: */[10, 16, 23],
    /*c6: */[11, 17, 24],
    /*c7: */[],

    /*d1: */[13, 26],
    /*d2: */[14, 20, 27],
    /*d3: */[15, 21, 28],
    /*d4: */[16, 22, 29],
    /*d5: */[17, 23, 30],
    /*d6: */[18, 24, 31],

    /*e1: */[],
    /*e2: */[20, 26, 33],
    /*e3: */[21, 27, 34],
    /*e4: */[22, 28, 35],
    /*e5: */[23, 29, 36],
    /*e6: */[24, 30, 37],
    /*e7: */[],

    /*f1: */[26, 39],
    /*f2: */[27, 33, 40],
    /*f3: */[28, 34, 41],
    /*f4: */[29, 35, 42],
    /*f5: */[30, 36, 43],
    /*f6: */[31, 37, 44],

    /*g1: */[],
    /*g2: */[33, 39, 46],
    /*g3: */[34, 40, 47],
    /*g4: */[35, 41, 48],
    /*g5: */[36, 42, 49],
    /*g6: */[37, 43, 50],
    /*g7: */[],

    /*h1: */[39, 52],
    /*h2: */[40, 46, 53],
    /*h3: */[41, 47, 54],
    /*h4: */[42, 48, 55],
    /*h5: */[43, 49, 56],
    /*h6: */[44, 50, 57],

    /*i1: */[],
    /*i2: */[46, 52],
    /*i3: */[47, 53],
    /*i4: */[48, 54],
    /*i5: */[49, 55],
    /*i6: */[50, 56],
    /*i7: */[],
];




const dMovesCount = [
    2, 4, 4, 4, 4, 4, 2,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    2, 4, 4, 4, 4, 4, 2
];

const iMovesCount = [
    2, 4, 4, 4, 4, 4, 2,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    2, 4, 4, 4, 4, 4, 2
];

const lShortMovesCount = [
    2, 4, 4, 4, 4, 4, 2,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    3, 6, 6, 6, 6, 6, 3,
    5, 6, 6, 6, 6, 5,
    2, 4, 4, 4, 4, 4, 2
];

const lLongMovesCount = [
    2, 3, 4, 4, 4, 3, 2,
    2, 3, 4, 4, 3, 2,
    3, 5, 6, 6, 6, 5, 3,
    3, 5, 6, 6, 5, 3,
    3, 5, 6, 6, 6, 5, 3,
    3, 5, 6, 6, 5, 3,
    3, 5, 6, 6, 6, 5, 3,
    2, 3, 4, 4, 3, 2,
    2, 3, 4, 4, 4, 3, 2
];

const aMovesCount = [
    8, 0, 0, 8, 0, 0, 8,
    0, 9, 0, 0, 9, 0,
    10, 0, 0, 12, 0, 0, 10,
    0, 11, 0, 0, 11, 0,
    12, 0, 0, 12, 0, 0, 12,
    0, 11, 0, 0, 11, 0,
    10, 0, 0, 12, 0, 0, 10,
    0, 9, 0, 0, 9, 0,
    8, 0, 0, 8, 0, 0, 8
];

const pMovesCount = [
    0, 2, 2, 2, 2, 2, 0,
    3, 3, 3, 3, 3, 2,
    0, 3, 3, 3, 3, 3, 0,
    3, 3, 3, 3, 3, 2,
    0, 3, 3, 3, 3, 3, 0,
    3, 3, 3, 3, 3, 2,
    0, 3, 3, 3, 3, 3, 0,
    3, 3, 3, 3, 3, 2,
    0, 2, 2, 2, 2, 2, 0
];

const PMovesCount = [
    0, 2, 2, 2, 2, 2, 0,
    2, 3, 3, 3, 3, 3,
    0, 3, 3, 3, 3, 3, 0,
    2, 3, 3, 3, 3, 3,
    0, 3, 3, 3, 3, 3, 0,
    2, 3, 3, 3, 3, 3,
    0, 3, 3, 3, 3, 3, 0,
    2, 3, 3, 3, 3, 3,
    0, 2, 2, 2, 2, 2, 0
];

const mMovesCount = [
    14, 16, 18, 18, 18, 16, 14,
    15, 17, 19, 19, 17, 15,
    14, 18, 20, 22, 20, 18, 14,
    15, 19, 21, 21, 19, 15,
    14, 18, 22, 22, 22, 18, 14,
    15, 19, 21, 21, 19, 15,
    14, 18, 20, 22, 20, 18, 14,
    15, 17, 19, 19, 17, 15,
    14, 16, 18, 18, 18, 16, 14
];

const distanceToCenter = [
    5, 4, 4, 4, 4, 4, 5,
    4, 3, 3, 3, 3, 4,
    4, 3, 2, 2, 2, 3, 4,
    3, 2, 1, 1, 2, 3,
    3, 2, 1, 0, 1, 2, 3,
    3, 2, 1, 1, 2, 3,
    4, 3, 2, 2, 2, 3, 4,
    4, 3, 3, 3, 3, 4,
    5, 4, 4, 4, 4, 4, 5,
];

const pPromotion = [
    0, 0, 20, 50, 100, 150, 0,
    0, 0, 20, 50, 100, 150,
    0, 0, 20, 50, 100, 150, 0,
    0, 0, 20, 50, 100, 150,
    0, 0, 20, 50, 100, 150, 0,
    0, 0, 20, 50, 100, 150,
    0, 0, 20, 50, 100, 150, 0,
    0, 0, 20, 50, 100, 150,
    0, 0, 20, 50, 100, 150, 0,
];

const PPromotion = [
    0, -150, -100, -50, -20, 0, 0,
       -150, -100, -50, -20, 0, 0,
    0, -150, -100, -50, -20, 0, 0,
       -150, -100, -50, -20, 0, 0,
    0, -150, -100, -50, -20, 0, 0,
       -150, -100, -50, -20, 0, 0,
    0, -150, -100, -50, -20, 0, 0,
       -150, -100, -50, -20, 0, 0,
    0, -150, -100, -50, -20, 0, 0,
];

const iPromotion = [
    0, 5, 10, 20, 50, 100, 100000,
    0, 5, 10, 20, 50, 100,
    0, 5, 10, 20, 50, 100, 100000,
    0, 5, 10, 20, 50, 100,
    0, 5, 10, 20, 50, 100, 100000,
    0, 5, 10, 20, 50, 100,
    0, 5, 10, 20, 50, 100, 100000,
    0, 5, 10, 20, 50, 100,
    0, 5, 10, 20, 50, 100, 100000,
];

const IPromotion = [
    -100000, -100, -50, -20, -10, -5, 0,
             -100, -50, -20, -10, -5, 0,
    -100000, -100, -50, -20, -10, -5, 0,
             -100, -50, -20, -10, -5, 0,
    -100000, -100, -50, -20, -10, -5, 0,
             -100, -50, -20, -10, -5, 0,
    -100000, -100, -50, -20, -10, -5, 0,
             -100, -50, -20, -10, -5, 0,
    -100000, -100, -50, -20, -10, -5, 0,
];

const kMovesCount = 5;
const kCenter = 5;
const price = [[],[],[],[],[],[],    [],[],[],[],[],[],   []];
for(let i = 0; i <= 58; i++) {
    price[0][i] = marks[0] + pMovesCount[i] * kMovesCount + pPromotion[i];
    price[1][i] = marks[1] - PMovesCount[i] * kMovesCount + PPromotion[i];

    price[2][i] = marks[2] + mMovesCount[i] * kMovesCount + distanceToCenter[i] * kCenter;
    price[3][i] = marks[3] - mMovesCount[i] * kMovesCount - distanceToCenter[i] * kCenter;

    price[4][i] = marks[4] + (lShortMovesCount[i] / 2 + lLongMovesCount[i]) * kMovesCount + distanceToCenter[i] * kCenter;
    price[5][i] = marks[5] - (lShortMovesCount[i] / 2 + lLongMovesCount[i]) * kMovesCount - distanceToCenter[i] * kCenter;

    price[6][i] = marks[6] + aMovesCount[i] * kMovesCount + 0 * distanceToCenter[i] * kCenter;
    price[7][i] = marks[7] - aMovesCount[i] * kMovesCount - 0 * distanceToCenter[i] * kCenter;

    price[8][i] = marks[8] + dMovesCount[i] * kMovesCount + distanceToCenter[i] * kCenter;
    price[9][i] = marks[9] - dMovesCount[i] * kMovesCount - distanceToCenter[i] * kCenter;

    price[10][i] = marks[10] + iMovesCount[i] * kMovesCount + iPromotion[i];
    price[11][i] = marks[11] - iMovesCount[i] * kMovesCount + IPromotion[i];

    price[12][i] = 0;
}

class Position {
    iPos;
    IPos;
    fields;
    order;

    moveHistory;
    hash;
    history;
    pruningHistory;
    zobristTable;
    positionHistory;

    get strFields() {
        let res = {};
        let i = 0;
        coords.forEach(coord => {
            res[coord] = ntof(this.fields[i]);
            i++;
        });
        return res;
    }

    constructor(position) {
        this.positionHistory = new Map();

        this.moveHistory = [];
        this.fields = [];

        this.initializeZobrist();

        if (position && position.order != undefined) {
            this.iPos = position.iPos;
            this.IPos = position.IPos;
            this.order = position.order;
            this.moveHistory = position.moveHistory;
            this.hash = position.hash;
            this.history = position.history;
            this.positionHistory = position.positionHistory;
            this.fields = position.fields;
            return;
        }

        if (position) {
            if (this.setPosition(position)) {
                return;
            }
        }

        for(let i = 0; i <= 58; i++)
            this.fields[i] = 12;

        this.fields[1] = this.fields[14] = this.fields[27] = this.fields[40] = this.fields[53] = 0;
        this.fields[0] = this.fields[52] = 2;
        this.fields[7] = this.fields[46] = 4;
        this.fields[13] = this.fields[39] = 6;
        this.fields[20] = this.fields[33] = 8;
        this.fields[26] = 10;

        this.fields[5] = this.fields[18] = this.fields[31] = this.fields[44] = this.fields[57] = 1;
        this.fields[6] = this.fields[58] = 3;
        this.fields[12] = this.fields[51] = 5;
        this.fields[19] = this.fields[45] = 7;
        this.fields[25] = this.fields[38] = 9;
        this.fields[32] = 11;

        this.order = 0;

        this.iPos = 26;
        this.IPos = 32;

        this.positionHistory.set(this.zobristHash(), 1);
    }

    initializeHistory() {
        this.history = [];
        for(let i = 0; i <= 58; i++) {
            this.history[i] = [];
            for(let j = 0; j <= 58; j++) {
                this.history[i][j] = [];
                for(let k = fton('p'); k <= fton('I'); k++) {
                    this.history[i][j][k] = 0;
                }
            }
        }
    }

    initializePruningHistory() {
        this.pruningHistory = [];
        for(let i = 0; i <= 58; i++) {
            this.pruningHistory[i] = [];
            for(let j = 0; j <= 58; j++) {
                this.pruningHistory[i][j] = [];
                for(let k = fton('p'); k <= fton('I'); k++) {
                    this.pruningHistory[i][j][k] = { all: 0, best: 0 };
                }
            }
        }
    }

    random32()
    {
        let n = 0;
        let m = 1;
        for (let i = 0; i < 32; i++)
        {
            let r = Math.round(Math.random());
            n += r * m;
            m *= 2;
        }
        return n;
    }

    initializeZobrist() {
        this.zobristTable = [];
        for(let i = 0; i <= 58; i++) {
            this.zobristTable[i] = [];
            for(let j = 0; j <= 11; j++) {
                this.zobristTable[i][j] = this.random32();
            }
            this.zobristTable[i][12] = 0;
        }
        this.zobristTable.blackMove = this.random32();
    }

    zobristHash() {
        let h = 0;
        if (this.order === 1) h ^= this.zobristTable.blackMove;
        for(let i = 0; i <= 58; i++) {
            const figure = this.fields[i];
            if (figure !== 12) h ^= this.zobristTable[i][figure];
        }

        return h;
    }

    recalculateZobristHash(parentZobrist, move) {
        parentZobrist ^= this.zobristTable.blackMove;

        const fromFigure = this.fields[move.from];
        const toFigure = this.fields[move.to];
        const newFromFigure = ((fromFigure === 10 && toFigure === 8) ||
                               (fromFigure === 11 && toFigure === 9)) ?
                               toFigure : 12;
        const newToFigure = move.figure;

        if (fromFigure !== 12) parentZobrist ^= this.zobristTable[move.from][fromFigure];
        if (toFigure !== 12) parentZobrist ^= this.zobristTable[move.to][toFigure];
        if (newFromFigure !== 12) parentZobrist ^= this.zobristTable[move.from][newFromFigure];
        if (newToFigure !== 12) parentZobrist ^= this.zobristTable[move.to][newToFigure];

        return parentZobrist;
    }

    setPosition(position) {
        if (position.length !== 60) return false;
        let qi = 0, qI = 0;

        for(let i = 0; i <= 58; i++) {
            this.fields[i] = fton(position[i]);
            if (position[i] === 'i') {
                this.iPos = i;
                qi++;
            } else
            if (position[i] === 'I') {
                this.IPos = i;
                qI++;
            }      
        }

        if (qi === 0) this.iPos = null;
        if (qI === 0) this.IPos = null;

        if (qi > 1 || qI > 1) return false;
        if (!['w', 'b'].includes(position[59])) return false;

        this.order = oton(position[59]);

        this.positionHistory = new Map();
        this.positionHistory.set(this.zobristHash(), 1);

        return true;
    }

    toString() {
        let res = '';

        for(let i = 0; i <= 58; i++)
            res += ntof(this.fields[i]);

        res += ntoo(this.order);
        
        return res;
    }

    tryMove(from, to) {
        if (typeof(from) === 'string') from = cton(from);
        if (typeof(to) === 'string') to = cton(to);

        const moves = this.getMoves();

        let possibleMoves = [];
        moves.forEach(move => {
            if ((move.from === from) && (move.to === to)) {
                possibleMoves.push(move);
            }
        });

        if (possibleMoves.length === 0) return false;

        let move;
        if (possibleMoves.length === 1) {
            move = possibleMoves[0];
        } else
        if (possibleMoves.length === 2) {
            let move0 = possibleMoves[0];
            let move1 = possibleMoves[1];

            let answer = confirm('А превращаться то будем?');

            if ((answer && this.fields[move0.from] !== move0.figure) ||
                (!answer && this.fields[move0.from] === move0.figure)) {
                move = move0;
            } else {
                move = move1;
            }
        } else
        if (possibleMoves.length === 4) {
            let answer = prompt('Во что превращаться то будем?');

            possibleMoves.forEach(m => {
                if (ntof(m.figure).toUpperCase() === answer.toUpperCase()) {
                    move = m;
                }
            });
        }

        this.moveByRules(move, this.recalculateZobristHash(this.zobristHash(), move));
        return true;
    }

    engineMove(move) {
        this.moveByRules(move, this.recalculateZobristHash(this.zobristHash(), move));
    }

    move(from, to) {
        if (from === to) return;
        
        this.moveHistory = [];

        if (typeof(from) === 'string') from = cton(from);
        if (typeof(to) === 'string') to = cton(to);

        if (this.fields[from] === 10) this.iPos = to; else
        if (this.fields[from] === 11) this.IPos = to;

        if (this.fields[to] === 10) this.iPos = null; else
        if (this.fields[to] === 11) this.IPos = null;     

        this.fields[to] = this.fields[from];
        this.fields[from] = 12;

        this.positionHistory = new Map();
    }

    strMoves() { // для клиента список ходов в строковом виде
        let res = [];
        this.moveHistory.forEach(move => {
            let figure = ntof(move.fromFigure).toUpperCase();
            if (figure === 'M') figure = 'D'; else
            if (figure === 'D') figure = 'F'; else
            if (figure === 'P') figure = '';

            let toFigure = ntof(move.newFigure).toUpperCase();
            if (toFigure === 'M') toFigure = 'D'; else
            if (toFigure === 'D') toFigure = 'F';

            const from = ntoc(move.from);
            const symbol = move.toFigure === 12 ? '-' : 'x';
            const to = ntoc(move.to);
            const magic = move.fromFigure !== move.newFigure ? '=' + toFigure : '';
            res.push(figure + from + symbol + to + magic);
        });
        return res;
    }

    moveByRules(move, hash) {
        const fromFigure = this.fields[move.from];
        const toFigure = this.fields[move.to];

        this.moveHistory.push({
            from: move.from,
            to: move.to,
            fromFigure: fromFigure,
            toFigure: toFigure,
            newFigure: move.figure
        });
        
        if (move.figure === 10) this.iPos = move.to; else
        if (move.figure === 11) this.IPos = move.to;

        if (toFigure === 10) this.iPos = null; else
        if (toFigure === 11) this.IPos = null;

        if ((fromFigure === 10 && toFigure === 8) ||
            (fromFigure === 11 && toFigure === 9)) {
                // верто
                this.fields[move.from] = toFigure;
                this.fields[move.to] = fromFigure;
            } else {
                // обычный ход
                this.fields[move.from] = 12;
                this.fields[move.to] = move.figure;
            }
                    
        this.order ^= 1;

        if (hash) {
            const val = this.positionHistory.get(hash);
            if (val === undefined) this.positionHistory.set(hash, 1); else
            this.positionHistory.set(hash, val + 1);
        }

        return this;
    }

    unmoveByRules(hash) {
        const move = this.moveHistory.pop();

        this.fields[move.from] = move.fromFigure;
        this.fields[move.to] = move.toFigure;

        if (move.fromFigure === 10) this.iPos = move.from; else
        if (move.fromFigure === 11) this.IPos = move.from;

        if (move.toFigure === 10) this.iPos = move.to; else
        if (move.toFigure === 11) this.IPos = move.to;

        this.order ^= 1;

        if (hash) {
            const val = this.positionHistory.get(hash);
            if (val === 1) this.positionHistory.delete(hash); else
            this.positionHistory.set(hash, val - 1);
        }

        return this;
    }

    setField(coord, figure) {
        this.moveHistory = [];

        if (typeof(coord) === 'string') coord = cton(coord);
        if (typeof(figure) === 'string') figure = fton(figure);

        this.fields[coord] = figure;

        if (figure === 10) this.iPos = coord; else
        if (figure === 11) this.IPos = coord;

        if (figure === 10 || figure === 11)
            for(let i = 0; i <= 58; i++) {
                if (this.fields[i] === figure && i !== coord) {
                    this.fields[i] = 12;
                }
            }

        this.positionHistory = new Map();
    }

    takeBack() { // возврат хода для клиента
        const historyMove = this.moveHistory[this.moveHistory.length - 1];
        const move = { from: historyMove.from, to: historyMove.to, figure: historyMove.newFigure };
        this.unmoveByRules();
        const hash = this.recalculateZobristHash(this.zobristHash(), move);
        this.moveByRules(move);
        this.unmoveByRules(hash);
    }

    gameResult() {
        const mark = this.fastMark();
        if (mark > 0.9 * marks[10]) return 'white';
        if (mark < 0.9 * marks[11]) return 'black';
        const values = [ ...this.positionHistory.values() ];
        for(let i = 0; i < values.length; i++)
            if (values[i] >= 3) return 'draw';
        return undefined;
    }

    passMove() {
        this.order ^= 1;
    }

    getMoves() {
        const moves = [];

        const getMMoves = (coord) => {
            const figure = this.fields[coord];
            const color = figure % 2;
            const fields = mMoves[coord];

            for(let dir = 0; dir < 6; dir++) 
                if (fields[dir].length !== 0) {
                    const line = fields[dir];
                    const length = line.length;
                    
                    let n = 0;
                    while (n < length && this.fields[line[n]] === 12) {
                        moves.push({ from: coord, to: line[n++], figure: figure });
                    }
                    
                    const beatingFigure = this.fields[line[n]];
                    if (n < length && beatingFigure % 2 !== color) {
                        moves.push({ from: coord, to: line[n], figure: figure });

                        // бой с превращением
                        if (beatingFigure !== changeRegister(figure) &&
                            beatingFigure !== 10 && beatingFigure !== 11)
                        if ((color === 0 && near[coord].includes(this.iPos)) ||
                            (color === 1 && near[coord].includes(this.IPos))) {
                            moves.push({ from: coord, to: line[n], figure: changeRegister(beatingFigure) });   
                        }
                    }
                }
        }

        const getAMoves = (coord) => {
            const figure = this.fields[coord];
            const color = figure % 2;
            const fields = aMoves[coord];

            for(let dir = 0; dir < 6; dir++) 
                if (fields[dir].length !== 0) {
                    const line = fields[dir];
                    const length = line.length;
                    
                    let n = 0;
                    while (n < length && this.fields[line[n]] === 12) {
                        moves.push({ from: coord, to: line[n++], figure: figure });
                    }
                    
                    const beatingFigure = this.fields[line[n]];
                    if (n < length && beatingFigure % 2 != color) {
                        moves.push({ from: coord, to: line[n], figure: figure });

                        // бой с превращением
                        if (beatingFigure !== changeRegister(figure) &&
                            beatingFigure !== 10 && beatingFigure !== 11)
                        if ((color === 0 && near[coord].includes(this.iPos)) ||
                            (color === 1 && near[coord].includes(this.IPos))) {
                            moves.push({ from: coord, to: line[n], figure: changeRegister(beatingFigure) });   
                        }
                    }
                }
        }

        const getDMoves = (coord) => {
            const figure = this.fields[coord];
            const color = figure % 2;
            const fields = dMoves[coord];

            fields.forEach(field => {
                if (this.fields[field] === 12 || this.fields[field] % 2 !== color) {
                    moves.push({ from: coord, to: field, figure: figure });
                }

                // если чужая фигура
                const beatingFigure = this.fields[field];
                if (beatingFigure !== 12 && beatingFigure % 2 !== color) {
                    // бой с превращением
                    if (beatingFigure !== changeRegister(figure) &&
                        beatingFigure !== 10 && beatingFigure !== 11)
                    if ((color === 0 && near[coord].includes(this.iPos)) ||
                        (color === 1 && near[coord].includes(this.IPos))) {
                            moves.push({ from: coord, to: field, figure: changeRegister(beatingFigure) });   
                    }
                }
            });
        }

        const getpMoves = (coord) => {
            const fields = pMoves[coord];

            fields.forEach(field => {
                if (this.fields[field] === 12 || this.fields[field] % 2 === 1) {
                    if (![6, 19, 32, 45, 58].includes(field)) {
                        moves.push({ from: coord, to: field, figure: 0 });
                    } else {
                        moves.push({ from: coord, to: field, figure: 2 });
                        moves.push({ from: coord, to: field, figure: 4 });
                        moves.push({ from: coord, to: field, figure: 6 });
                        moves.push({ from: coord, to: field, figure: 8 });
                    }
                }
            });
        }

        const getPMoves = (coord) => {
            const fields = PMoves[coord];

            fields.forEach(field => {
                if (this.fields[field] === 12 || this.fields[field] % 2 === 0) {
                    if (![0, 13, 26, 39, 52].includes(field)) {
                        moves.push({ from: coord, to: field, figure: 1 });
                    } else {
                        moves.push({ from: coord, to: field, figure: 3 });
                        moves.push({ from: coord, to: field, figure: 5 });
                        moves.push({ from: coord, to: field, figure: 7 });
                        moves.push({ from: coord, to: field, figure: 9 });
                    }
                }
            });
        }

        const getLMoves = (coord) => {
            const figure = this.fields[coord];
            const color = figure % 2;
            let fields = lLongMoves[coord];

            fields.forEach(field => {
                if (this.fields[field] === 12 || this.fields[field] % 2 !== color) {
                    moves.push({ from: coord, to: field, figure: figure });
                }

                // если чужая фигура
                const beatingFigure = this.fields[field];
                if (beatingFigure !== 12 && beatingFigure % 2 != color) {
                    // бой с превращением
                    if (beatingFigure !== changeRegister(figure) &&
                        beatingFigure !== 10 && beatingFigure !== 11)
                    if ((color === 0 && near[coord].includes(this.iPos)) ||
                        (color === 1 && near[coord].includes(this.IPos))) {
                            moves.push({ from: coord, to: field, figure: changeRegister(beatingFigure) });   
                    }
                }
            });

            // ходы на одну клетку без боя
            fields = lShortMoves[coord];

            fields.forEach(field => {
                if (this.fields[field] === 12) {
                    moves.push({ from: coord, to: field, figure: figure });
                }
            });
        }

        const getIMoves = (coord) => {
            const figure = this.fields[coord];
            const color = figure % 2;
            const fields = iMoves[coord];

            fields.forEach(field => {
                if (this.fields[field] === 12) {
                    moves.push({ from: coord, to: field, figure: figure });
                }

                if ((color === 0 && this.fields[field] === 8) ||
                    (color === 1 && this.fields[field] === 9)) {
                    moves.push({ from: coord, to: field, figure: figure });
                }
            });
        }

        for(let i = 0; i <= 58; i++) {
            const figure = this.fields[i];

            if ((figure !== 12) && (figure % 2 === this.order))
                switch (figure) {
                    case 0:
                        getpMoves(i);
                        break;     
                    case 1:
                        getPMoves(i);
                        break;                
                    case 2: case 3:
                        getMMoves(i);
                        break;
                    case 6: case 7:
                        getAMoves(i);
                        break;
                    case 8: case 9:
                        getDMoves(i);
                        break;
                    case 4: case 5:
                        getLMoves(i);
                        break;
                    case 10: case 11:
                        getIMoves(i);
                        break;
                }
        };

        return moves;
    }

    getBeatMoves() {
        const moves = [];
        const color = this.order;

        const getMMoves = (coord) => {
            const figure = this.fields[coord];
            const fields = mMoves[coord];

            for(let dir = 0; dir < 6; dir++) 
                if (fields[dir].length !== 0) {
                    const line = fields[dir];
                    
                    let n = 0;
                    const length = line.length;
                    while (n < length && this.fields[line[n]] === 12)
                        n++;
                    
                    if (n < length) {
                        const beatingFigure = this.fields[line[n]];
                        if (beatingFigure % 2 !== color) {
                            moves.push({ from: coord, to: line[n], figure: figure });

                            // бой с превращением
                            if (beatingFigure !== changeRegister(figure) &&
                                beatingFigure !== 10 && beatingFigure !== 11)
                            if ((color === 0 && near[coord].includes(this.iPos)) ||
                                (color === 1 && near[coord].includes(this.IPos))) {
                                    moves.push({ from: coord, to: line[n], figure: changeRegister(beatingFigure) });   
                            }
                        }
                    }
                }
        }

        const getAMoves = (coord) => {
            const figure = this.fields[coord];
            const fields = aMoves[coord];

            for(let dir = 0; dir < 6; dir++) 
                if (fields[dir].length !== 0) {
                    const line = fields[dir];
                    
                    let n = 0;
                    const length = line.length;
                    while (n < length && this.fields[line[n]] === 12)
                        n++;
                    
                    if (n < length) {
                        const beatingFigure = this.fields[line[n]];
                        if (beatingFigure % 2 !== color) {
                            moves.push({ from: coord, to: line[n], figure: figure });

                            // бой с превращением
                            if (beatingFigure !== changeRegister(figure) &&
                                beatingFigure !== 10 && beatingFigure !== 11)
                            if ((color === 0 && near[coord].includes(this.iPos)) ||
                                (color === 1 && near[coord].includes(this.IPos))) {
                                    moves.push({ from: coord, to: line[n], figure: changeRegister(beatingFigure) });   
                            }
                        }
                    }
                }
        }

        const getDMoves = (coord) => {
            const figure = this.fields[coord];
            const fields = dMoves[coord];

            const length = fields.length;
            for (let i = 0; i < length; i++) {
                const field = fields[i];
                const beatingFigure = this.fields[field];

                if (beatingFigure !== 12 && beatingFigure % 2 !== color) {
                    moves.push({ from: coord, to: field, figure: figure });

                    // бой с превращением
                    if (beatingFigure !== changeRegister(figure) &&
                        beatingFigure !== 10 && beatingFigure !== 11)
                    if ((color === 0 && near[coord].includes(this.iPos)) ||
                        (color === 1 && near[coord].includes(this.IPos))) {
                            moves.push({ from: coord, to: field, figure: changeRegister(beatingFigure) });   
                    }
                }
            }
        }

        const getpMoves = (coord) => {
            const fields = pMoves[coord];

            const length = fields.length;
            for (let i = 0; i < length; i++) {
                const field = fields[i];
                const beatingFigure = this.fields[field];
                
                if (beatingFigure !== 12 && beatingFigure % 2 !== color) {
                    if (![6, 19, 32, 45, 58].includes(field)) {
                        moves.push({ from: coord, to: field, figure: 0 });
                    } else {
                        moves.push({ from: coord, to: field, figure: 2 });
                        moves.push({ from: coord, to: field, figure: 4 });
                        moves.push({ from: coord, to: field, figure: 6 });
                        moves.push({ from: coord, to: field, figure: 8 });
                    }
                }
            }
        }

        const getPMoves = (coord) => {
            const fields = PMoves[coord];

            const length = fields.length;
            for (let i = 0; i < length; i++) {
                const field = fields[i];
                const beatingFigure = this.fields[field];
                
                if (beatingFigure !== 12 && beatingFigure % 2 !== color) {
                    if (![0, 13, 26, 39, 52].includes(field)) {
                        moves.push({ from: coord, to: field, figure: 1 });
                    } else {
                        moves.push({ from: coord, to: field, figure: 3 });
                        moves.push({ from: coord, to: field, figure: 5 });
                        moves.push({ from: coord, to: field, figure: 7 });
                        moves.push({ from: coord, to: field, figure: 9 });
                    }
                }
            }
        }

        const getLMoves = (coord) => {
            const figure = this.fields[coord];
            let fields = lLongMoves[coord];

            const length = fields.length;
            for (let i = 0; i < length; i++) {
                const field = fields[i];
                const beatingFigure = this.fields[field];
                
                if (beatingFigure !== 12 && beatingFigure % 2 !== color) {
                    moves.push({ from: coord, to: field, figure: figure });
                
                    // бой с превращением
                    if (beatingFigure !== changeRegister(figure) &&
                        beatingFigure !== 10 && beatingFigure !== 11)
                    if ((color === 0 && near[coord].includes(this.iPos)) ||
                        (color === 1 && near[coord].includes(this.IPos))) {
                            moves.push({ from: coord, to: field, figure: changeRegister(beatingFigure) });   
                    }
                }
            }
        }

        for(let i = 0; i <= 58; i++) {
            const figure = this.fields[i];

            if ((figure !== 12) && (figure % 2 === this.order))
                switch (figure) {
                    case 0:
                        getpMoves(i);
                        break;     
                    case 1:
                        getPMoves(i);
                        break;                
                    case 2: case 3:
                        getMMoves(i);
                        break;
                    case 6: case 7:
                        getAMoves(i);
                        break;
                    case 8: case 9:
                        getDMoves(i);
                        break;
                    case 4: case 5:
                        getLMoves(i);
                        break;
                }
        };
        return moves;
    }

    getStrMoves() {
        let moves = this.getMoves();
        moves.forEach(move => {
            move.from = ntoc(move.from);
            move.to = ntoc(move.to);
            move.figure = ntof(move.figure);
        });
        return moves;
    }

    sortBeatMoves(moves) {
        const moveMarks = [];
        const length = moves.length;
        for (let i = 0; i < length; i++) {
            const move = moves[i];
            moveMarks[i] = -marks[this.fields[move.to]] - marks[this.fields[move.from]];
        }

        if (this.order === 0) {
            for (let j = length - 2; j >= 0; j--)
                for (let i = 0; i <= j; i++)
                    if (moveMarks[i] < moveMarks[i + 1]) {
                        const tmpMark = moveMarks[i];
                        moveMarks[i] = moveMarks[i + 1];
                        moveMarks[i + 1] = tmpMark;

                        const tmpMove = moves[i];
                        moves[i] = moves[i + 1];
                        moves[i + 1] = tmpMove;
                    }
        } else {
            for (let j =length - 2; j >= 0; j--)
                for (let i = 0; i <= j; i++)
                    if (moveMarks[i] > moveMarks[i + 1]) {
                        const tmpMark = moveMarks[i];
                        moveMarks[i] = moveMarks[i + 1];
                        moveMarks[i + 1] = tmpMark;

                        const tmpMove = moves[i];
                        moves[i] = moves[i + 1];
                        moves[i + 1] = tmpMove;
                    }
        }

        return moves;
    }

    quiesce2(α, β) {
        const fullDepth = 2;
        const beatFields = [];

        const quiesce = (depth, α, β, mark) => {
            let stand_pat = mark === undefined ? this.fastMark() : mark;
            if (Math.abs(stand_pat) > 0.9 * marks[10]) return stand_pat;

            if (this.order === 0) {
                if (stand_pat >= β) return stand_pat;
                if (α < stand_pat) α = stand_pat;
            
                const moves = this.getBeatMoves();
                this.sortBeatMoves(moves);

                const length = moves.length;
                for(let i = 0; i < length; i++) {
                        const move = moves[i];

                        if (depth >= fullDepth && !beatFields.includes(move.to) &&
                            this.fields[move.to] !== 10 && this.fields[move.to] !== 11) continue;

                        const newMark = this.recalculateMark(stand_pat, move);

                        this.moveByRules(move);
                        beatFields.push(move.to);
                        const mark = quiesce(depth + 1, α, β, newMark);
                        beatFields.pop();
                        this.unmoveByRules();
                
                        if (mark >= β) return mark;
                        if (mark > α) α = mark;
                    }
                return α;
            } else {
                if (stand_pat <= α) return stand_pat;
                if (β > stand_pat) β = stand_pat;
            
                const moves = this.getBeatMoves();
                this.sortBeatMoves(moves);

                const length = moves.length;
                for(let i = 0; i < length; i++) {
                        const move = moves[i];

                        if (depth >= fullDepth && !beatFields.includes(move.to) &&
                            this.fields[move.to] !== 10 && this.fields[move.to] !== 11) continue;

                        const newMark = this.recalculateMark(stand_pat, move);

                        this.moveByRules(move);
                        beatFields.push(move.to);
                        const mark = quiesce(depth + 1, α, β, newMark);
                        beatFields.pop();
                        this.unmoveByRules();
                
                        if (mark <= α) return mark;
                        if (mark < β) β = mark;
                    }
                return β;
            }
        }

        return quiesce(0, α, β);
    }

    fastMark() {
        let mark = 0;
        for(let i = 0; i <= 58; i++) {
            const figure = this.fields[i];
            if (figure !== 12) mark += price[figure][i];
        }
        if (mark > 0.9 * marks[10]) mark = marks[10]; else
        if (mark < 0.9 * marks[11]) mark = marks[11];
        if (mark < marks[10] * 0.9 && mark > marks[11] * 0.9)
        mark += this.variabilityArray[this.currentLine];
        return mark;
    }

    recalculateMark(mark, move) {
        mark -= price[this.fields[move.from]][move.from];
        mark -= price[this.fields[move.to]][move.to];
        mark += price[move.figure][move.to];

        if (mark > 0.9 * marks[10]) mark = marks[10]; else
        if (mark < 0.9 * marks[11]) mark = marks[11];
        return mark;
    }

    isCheck() {
        if (this.iPos === null || this.IPos === null) return false;

        const field = this.order === 0 ? this.iPos : this.IPos;
        const order = this.order ^ 1;

        // дефенсоры
        for(let dField of dMoves[field])
            if (this.fields[dField] === 8 + order)
                return true;

        // либераторы
        for (let lField of lLongMoves[field])
            if (this.fields[lField] === 4 + order)
                return true;

        // белые прогрессоры
        if (order === 0)
        for(let pField of PMoves[field])
            if (this.fields[pField] === 0)
                return true;

        // черные прогрессоры
        if (order === 1)
        for(let PField of pMoves[field])
            if (this.fields[PField] === 1)
                return true;

        // агрессоры
        for(let dir = 0; dir < 6; dir++) {
            const line = aMoves[field][dir];
            for(let i = 0; i < line.length; i++) {
                const figure = this.fields[line[i]];

                if (figure === 6 + order)
                    return true;

                if (figure !== 12) break;
            }
        }

        // доминаторы
        for(let dir = 0; dir < 6; dir++) {
            const line = mMoves[field][dir];
            for(let i = 0; i < line.length; i++) {
                const figure = this.fields[line[i]];

                if (figure === 2 + order)
                    return true;
                
                if (figure !== 12) break;
            }
        }   

        return false;
    }

    isCheckAfterMove(move) {
        this.moveByRules(move);
        const res = this.isCheck();
        this.unmoveByRules();
        return res;
    }

    isBeat(move) {
        if (this.fields[move.to] !== 12 &&
            this.fields[move.from] !== 10 &&
            this.fields[move.from] !== 11) return true;
        return false;
    }

    winMark() {
        if (this.iPos === undefined || this.iPos === null) return marks[11];
        if (this.IPos === undefined || this.IPos === null) return marks[10];
        if (this.iPos === 6  || this.iPos === 19  || this.iPos === 32 ||
            this.iPos === 45 || this.iPos === 58) return marks[10];
        if (this.IPos === 0  || this.IPos === 13  || this.IPos === 26 ||
            this.IPos === 39 || this.IPos === 52) return marks[11];
        return false;
    }

    seeHash(pos, α, β, depth) {
        const records = this.hash.get(pos);
        let bestMove;

        if (records) {
            let hashα = -Infinity, hashβ = +Infinity;

            for(let record of records)
                if (record.depth >= depth) {
                    if (record.mark > record.α && record.mark < record.β) return { mark: record.mark, move: record.move }
                    if (record.mark >= record.β && hashα < record.β) { hashα = record.β; bestMove = record.move; }
                    if (record.mark <= record.α && hashβ > record.α) hashβ = record.α;
                }

            if (α >= hashβ) return { mark: α };
            if (β <= hashα) return { mark: β };

            if (hashα <= hashβ) {
            α = Math.max(α, hashα - ε);
            β = Math.min(β, hashβ + ε);
            }

            //if (hashα > hashβ) return { move: bestMove, mark: hashα };

            return { newα: α, newβ: β };
        }
    }

    addToHash(pos, α, β, move, mark, depth) {
        if (!this.hash.has(pos)) {
            this.hash.set(pos, []);
        }

        let trustα, trustβ;
        if (mark <= α) {
            trustα = mark;
            trustβ = +Infinity;
        } else
        if (mark >= β) {
            trustα = -Infinity;
            trustβ = mark;
        } else
        if (mark > α && mark < β) {
            trustα = -Infinity;
            trustβ = +Infinity;
        }

        if (((trustα > marks[11]) || (trustβ < marks[10])) && (Math.abs(mark) > 0.9 * marks[10]))
            return;

        const records = this.hash.get(pos);

        for(let i = records.length - 1; i >= 0; i--) {
            const record = records[i];
            if (record.depth <= depth && record.α >= trustα && record.β <= trustβ) records.splice(i, 1);
        }

        records.push({
            move: move,
            depth: depth,
            mark: mark,
            α: trustα,
            β: trustβ,
        });
    }

    sortMoves(moves) {
        const parentZobrist = this.zobristHash();

        const order = this.order;
        const moveMarks = [];
        const length = moves.length;
        for (let i = 0; i < length; i++) {
            const move = moves[i];
            let depth = -1;
        
            const childZobrist = this.recalculateZobristHash(parentZobrist, move);

            this.moveByRules(move);
            const res = this.winMark();
            if (res) {
                moveMarks[i] = res;
            } else {
                const records = this.hash.get(childZobrist);
                if (records) {
                    const length = records.length;
                    for (let j = 0; j < length; j++) {
                        const record = records[j];
                        if (record.depth > depth) {
                            if (record.mark > record.α &&
                                record.mark < record.β)
                                moveMarks[i] = record.mark + record.depth * marks[order === 0 ? 0 : 1];
                                else
                            if (order === 0 && record.mark >= record.β)
                                moveMarks[i] = record.β + record.depth * marks[order === 0 ? 0 : 1];
                                else
                            if (order === 1 && record.mark <= record.α)
                                moveMarks[i] = record.α + record.depth * marks[order === 0 ? 0 : 1];

                            depth = record.depth;
                        }
                    }
                }
            }
            this.unmoveByRules();
            
            if (moveMarks[i] === undefined && this.fields[move.to] === 12) {
                const record = this.history[move.from][move.to][move.figure];
                moveMarks[i] = ((order === 0) ? marks[11] : marks[10]);
                if (order === 0) moveMarks[i] += record / 1000000; else
                moveMarks[i] -= record / 1000000;
            }

            if (moveMarks[i] === undefined) {
                const d = (-marks[this.fields[move.to]] - marks[this.fields[move.from]]);
                moveMarks[i] = order === 0 ? marks[11] + d: marks[10] + d;
            }
        }

        if (this.order === 0) {
            for (let j = length - 2; j >= 0; j--)
                for (let i = 0; i <= j; i++)
                    if (moveMarks[i] < moveMarks[i + 1]) {
                        const tmpMark = moveMarks[i];
                        moveMarks[i] = moveMarks[i + 1];
                        moveMarks[i + 1] = tmpMark;

                        const tmpMove = moves[i];
                        moves[i] = moves[i + 1];
                        moves[i + 1] = tmpMove;
                    }
        } else {
            for (let j = length - 2; j >= 0; j--)
                for (let i = 0; i <= j; i++)
                    if (moveMarks[i] > moveMarks[i + 1]) {
                        const tmpMark = moveMarks[i];
                        moveMarks[i] = moveMarks[i + 1];
                        moveMarks[i + 1] = tmpMark;

                        const tmpMove = moves[i];
                        moves[i] = moves[i + 1];
                        moves[i + 1] = tmpMove;
                    }
        }
        
        return moves;
    }

    quesceTime = 0;
    sortTime = 0;
    stringTime = 0;
    hashTime = 0;

    count = 0;

    αβ(α, β, depth, extension, maxDepth, pos, firstDepth) {
        const sortDepth = 2;
        const hashDepth = 2;
        const repetitionDepth = 2; // обязательно не больше hashDepth !!!
        const drawMark = -0.1;

        if (pos == null)
        pos = this.zobristHash();

        this.count++;

        function correctWinMark(value) {
            if (value > 0.9 * marks[10]) return --value;
            if (value < 0.9 * marks[11]) return ++value;
            return value;
        }

        let result;
        let bestMove, isBestBeat, isBestCheck;
        const [oldα, oldβ] = [α, β];

        //#region расчет глубины
        while (extension >= 1) {
            depth++;
            extension--;
        }

        while (extension <= -1) {
            depth = Math.max(0, depth - 1);
            extension++;
        }
        //#endregion

        //#region троекратное повторение
        if (depth >= repetitionDepth && depth != maxDepth) {
            const record = this.positionHistory.get(pos);
            if (record !== undefined && record >= 2) return { mark: drawMark };
        }
        //#endregion

        //#region смотрим в хэше
        if (depth >= hashDepth) {
            const res = this.seeHash(pos, α, β, depth);
            if (res && res.mark !== undefined) return res;
            if (res && res.newα !== undefined) [α, β] = [res.newα, res.newβ];
        }
        //#endregion

        if (α < 0.9 * marks[11]) α = marks[11];
        if (β > 0.9 * marks[10]) β = marks[10];// фатовые оценки нельзя подрезать

        //#region null-pruning
        if (depth >= 1 && depth <= 1) {
            this.order ^= 1;
            let isNullPruning = false;
            let nullMark;
            if (this.order === 1 && β < +Infinity) {
                nullMark = this.αβ(β - 1, β, depth - 1, extension).mark;
                if (nullMark >= β) isNullPruning = true;
            }
                else
            if (this.order === 0 && α > -Infinity)
            {
                nullMark = this.αβ(α, α + 1, depth - 1, extension).mark;
                if (nullMark <= α) isNullPruning = true;
            }
            this.order ^= 1;
            if (isNullPruning) return { mark: nullMark };
        }
        //#endregion

        //#region выигрышная позиция
        const mark = this.winMark();
        if (mark !== false) {
            return { mark: mark };
        }
        //#endregion

        //#region поверхностная оценка
        if (depth < 1) {
            const mark = this.quiesce2(α, β);
            result = mark;
        }
        //#endregion
            else
        //#region максимизатор
        if (this.order === 0) {
            let value = marks[11];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            for(let i = 0; i < length; i++) {
                if (firstDepth) this.currentLine = i;
                const move = moves[i];

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                let ext = Math.max(beat, check);

                if (!ext)
                {
                    if (this.pruningHistory[move.from][move.to][move.figure].all >= maxDepth * maxDepth * 2)
                    {
                        let p = this.pruningHistory[move.from][move.to][move.figure].best / this.pruningHistory[move.from][move.to][move.figure].all;
                        ext = -1 / (100 * p + 0.5);
                    }
                    if (depth >= sortDepth) 
                    {
                        const records = this.hash.get(p);
                        let d = 0;
                        if (records)
                        for(let record of records)
                            if (record.depth > d) 
                                d = record.depth;
                        if (d >= 3)
                        {
                            ext -= i / length;
                        }
                    }
                }
                
                let res;
                if (i >= 1 && β - α > 1) {
                    res = this.αβ(α, α + 1, depth - 1, extension + ext, maxDepth, p).mark;
                    if (res >= α + 1 && res < β) res = this.αβ(res - 1, β, depth - 1, extension + ext, maxDepth, p).mark;
                } else {
                    res = this.αβ(α, β, depth - 1, extension + ext, maxDepth, p).mark;
                }
                res = correctWinMark(res);
                
                this.unmoveByRules(argP);
                //#endregion
                
                value = Math.max(value, res);

                if (!beat && !check) this.pruningHistory[move.from][move.to][move.figure].all++;
                
                if (value > α) {
                    α = value;
                    bestMove = move;
                    isBestBeat = beat;
                    isBestCheck = check;
                }

                if (value >= β) {
                    //#region эвристика истории
                    if (!beat) this.history[move.from][move.to][move.figure] += depth * depth;
                    //#endregion
                    break;
                }
            }

            result = value;
        }
        //#endregion
            else
        //#region минимизатор
        if (this.order === 1) {
            let value = marks[10];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            for(let i = 0; i < length; i++) {
                if (firstDepth) this.currentLine = i;
                const move = moves[i];

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                let ext = Math.max(beat, check);

                if (!ext)
                {
                    if (this.pruningHistory[move.from][move.to][move.figure].all >= maxDepth * maxDepth * 2)
                    {
                        let p = this.pruningHistory[move.from][move.to][move.figure].best / this.pruningHistory[move.from][move.to][move.figure].all;
                        ext = -1 / (100 * p + 0.5);
                    }
                    if (depth >= sortDepth) 
                    {
                        const records = this.hash.get(p);
                        let d = 0;
                        if (records)
                        for(let record of records)
                            if (record.depth > d) 
                                d = record.depth;
                        if (d >= 3)
                        {
                            ext -= i / length;
                        }
                    }
                }

                let res;
                if (i >= 1 && β - α > 1) {
                    res = this.αβ(β - 1, β, depth - 1, extension + ext, maxDepth, p).mark;
                    if (res > α && res <= β - 1) res = this.αβ(α, res + 1, depth - 1, extension + ext, maxDepth, p).mark;
                } else {
                    res = this.αβ(α, β, depth - 1, extension + ext, maxDepth, p).mark;
                }
                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                value = Math.min(value, res);
                
                if (!beat && !check) this.pruningHistory[move.from][move.to][move.figure].all++;

                if (value < β) {
                    β = value;
                    bestMove = move;
                    isBestBeat = beat;
                    isBestCheck = check;
                }

                let r = Math.random() * this.variability;
                if (value <= α) {
                    //#region эвристика истории
                    if (!beat) this.history[move.from][move.to][move.figure] += depth * depth;
                    //#endregion
                    break;
                }
            }
            result = value;
        }
        //#endregion

        //#region history pruning
        if (bestMove && !isBestBeat && !isBestCheck) this.pruningHistory[bestMove.from][bestMove.to][bestMove.figure].best++;
        //#endregion

        //#region заносим в хэш
        if (depth >= hashDepth && result !== drawMark) {
            this.addToHash(pos, oldα, oldβ, bestMove, result, depth);
        }
        //#endregion

        return { move: bestMove, mark: result };
    }

    cleanαβ(α, β, depth, extension, maxDepth, pos) {
        const sortDepth = 2;
        const hashDepth = 2;
        const repetitionDepth = 2; // обязательно не больше hashDepth !!!
        const drawMark = -0.1;

        if (pos == null)
        pos = this.zobristHash();

        this.count++;

        function correctWinMark(value) {
            if (value > 0.9 * marks[10]) return --value;
            if (value < 0.9 * marks[11]) return ++value;
            return value;
        }

        let result;
        let bestMove;
        const [oldα, oldβ] = [α, β];

        //#region расчет глубины
        if (extension >= 1) {
            depth++;
            extension--;
        }
        //#endregion

        //#region троекратное повторение
        if (depth >= repetitionDepth && depth != maxDepth) {
            const record = this.positionHistory.get(pos);
            if (record !== undefined && record >= 2) return { mark: drawMark };
        }
        //#endregion

        //#region смотрим в хэше
        if (depth >= hashDepth) {
            const res = this.seeHash(pos, α, β, depth);
            if (res && res.mark !== undefined) return res;
            if (res && res.newα !== undefined) [α, β] = [res.newα, res.newβ];
        }
        //#endregion

        if (α < 0.9 * marks[11]) α = marks[11];
        if (β > 0.9 * marks[10]) β = marks[10];// фатовые оценки нельзя подрезать

        //#region выигрышная позиция
        const mark = this.winMark();
        if (mark !== false) {
            return { mark: mark };
        }
        //#endregion

        //#region поверхностная оценка
        if (depth < 1) {
            const mark = this.quiesce2(α, β);
            result = mark;
        }
        //#endregion
            else
        //#region максимизатор
        if (this.order === 0) {
            let value = marks[11];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            for(let i = 0; i < length; i++) {
                const move = moves[i];

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                const ext = Math.max(beat, check);

                let res;
                if (i >= 1 && β - α > 1) {
                    res = this.cleanαβ(α, α + 1, depth - 1, extension + ext, maxDepth, p).mark;
                    if (res >= α + 1 && res < β) res = this.cleanαβ(res - 1, β, depth - 1, extension + ext, maxDepth, p).mark;
                } else {
                    res = this.cleanαβ(α, β, depth - 1, extension + ext, maxDepth, p).mark;
                }
                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                value = Math.max(value, res);

                if (value > α) {
                    α = value;
                    bestMove = move;
                }

                if (value >= β) {
                    break;
                }
            }
            
            result = value;
        }
        //#endregion
            else
        //#region минимизатор
        if (this.order === 1) {
            let value = marks[10];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            for(let i = 0; i < length; i++) {
                const move = moves[i];

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                const ext = Math.max(beat, check);

                let res;
                if (i >= 1 && β - α > 1) {
                    res = this.cleanαβ(β - 1, β, depth - 1, extension + ext, maxDepth, p).mark;
                    if (res > α && res <= β - 1) res = this.cleanαβ(α, res + 1, depth - 1, extension + ext, maxDepth, p).mark;
                } else {
                    res = this.cleanαβ(α, β, depth - 1, extension + ext, maxDepth, p).mark;
                }
                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                value = Math.min(value, res); 

                if (value < β) {
                    β = value;
                    bestMove = move;
                }

                if (value <= α) {
                    break;
                }
            }

            result = value;
        }
        //#endregion

        //#region заносим в хэш
        if (depth >= hashDepth && result !== drawMark) {
            this.addToHash(pos, oldα, oldβ, bestMove, result, depth);
        }
        //#endregion

        return { move: bestMove, mark: result };
    }

    finish = 0;
    bestMoveInf = {};

    αβByTime(α, β, depth, extension, maxDepth, pos, firstDepth) {
        if (depth > 0 && maxDepth > 1 && this.finish - performance.now() < 0) {
            if (this.order === 0) return { mark: +Infinity};
            return { mark: -Infinity};
        }

        const sortDepth = 2;
        const hashDepth = 2;
        const repetitionDepth = 2; // обязательно не больше hashDepth !!!
        const drawMark = -0.1;

        if (pos == null)
        pos = this.zobristHash();

        this.count++;

        function correctWinMark(value) {
            if (value > 0.9 * marks[10]) return --value;
            if (value < 0.9 * marks[11]) return ++value;
            return value;
        }

        let result;
        let bestMove, isBestBeat, isBestCheck;
        let line, bestLine = [];
        const [oldα, oldβ] = [α, β];

        //#region расчет глубины
        while (extension >= 1) {
            depth++;
            extension--;
        }

        while (extension <= -1) {
            depth = Math.max(0, depth - 1);
            extension++;
        }
        //#endregion

        //#region троекратное повторение
        if (depth >= repetitionDepth && depth != maxDepth) {
            const record = this.positionHistory.get(pos);
            if (record !== undefined && record >= 2) return { mark: drawMark };
        }
        //#endregion

        //#region смотрим в хэше
        if (depth >= hashDepth) {
            const res = this.seeHash(pos, α, β, depth);
            if (res && res.mark !== undefined) return res;
            if (res && res.newα !== undefined) [α, β] = [res.newα, res.newβ];
        }
        //#endregion

        if (α < 0.9 * marks[11]) α = marks[11];
        if (β > 0.9 * marks[10]) β = marks[10];// фатовые оценки нельзя подрезать

        //#region null-pruning
        if (depth >= 1 && depth <= 1) {
            this.order ^= 1;
            let isNullPruning = false;
            let nullMark;
            if (this.order === 1 && β < +Infinity) {
                nullMark = this.αβByTime(β - 1, β, depth - 1, extension).mark;
                if (nullMark >= β) isNullPruning = true;
            }
                else
            if (this.order === 0 && α > -Infinity)
            {
                nullMark = this.αβByTime(α, α + 1, depth - 1, extension).mark;
                if (nullMark <= α) isNullPruning = true;
            }
            this.order ^= 1;
            if (isNullPruning) return { mark: nullMark };
        }
        //#endregion

        //#region выигрышная позиция
        const mark = this.winMark();
        if (mark !== false) {
            return { mark: mark };
        }
        //#endregion
            else
        //#region поверхностная оценка
        if (depth < 1) {
            const mark = this.quiesce2(α, β);
            result = mark;
        }
        //#endregion
            else
        //#region максимизатор
        if (this.order === 0) {
            let value = marks[11];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            let i = 0;
            for( ; i < length; i++) {
                const move = moves[i];
                if (firstDepth) this.currentLine = this.getMoveNumber(move);

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                let ext = Math.max(beat, check);

                if (!ext)
                {
                    if (this.pruningHistory[move.from][move.to][move.figure].all >= maxDepth * maxDepth * 2)
                    {
                        let p = this.pruningHistory[move.from][move.to][move.figure].best / this.pruningHistory[move.from][move.to][move.figure].all;
                        ext = -1 / (100 * p + 0.5);
                    }
                    if (depth >= sortDepth) 
                    {
                        const records = this.hash.get(p);
                        let d = 0;
                        if (records)
                        for(let record of records)
                            if (record.depth > d) 
                                d = record.depth;
                        if (d >= 3)
                        {
                            ext -= i / length;
                        }
                    }
                }

                let res, r;
                if (i >= 1 && β - α > 1) {
                    r = this.αβByTime(α, α + 1, depth - 1, extension + ext, maxDepth, p);
                    res = r.mark;
                    line = (r.line != undefined) ? r.line : [];
                    line.push(move);
                    if (res >= α + 1 && res < β) 
                    {
                        r = this.αβByTime(res - 1, β, depth - 1, extension + ext, maxDepth, p);
                        res = r.mark;
                        line = (r.line != undefined) ? r.line : [];
                        line.push(move);
                    }
                } else {
                    r = this.αβByTime(α, β, depth - 1, extension + ext, maxDepth, p);
                    res = r.mark;
                    line = (r.line != undefined) ? r.line : [];
                    line.push(move);
                }

                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                if (value < Math.max(value, res))
                {
                    value = Math.max(value, res);
                    bestLine = Array.from(line);
                }

                if (!beat && !check) this.pruningHistory[move.from][move.to][move.figure].all++;

                if (value > α) {
                    α = value;
                    bestMove = move;
                    isBestBeat = beat;
                    isBestCheck = check;
                }

                if (value >= β) {
                    //#region эвристика истории
                    if (!beat) this.history[move.from][move.to][move.figure] += depth * depth;
                    //#endregion
                    break;
                }

                if (bestMove && depth === maxDepth && (this.finish - performance.now() > 0 || maxDepth <= 1)) {
                    for (let j = 0; j <= i; j++)
                    if  ((this.bestMoveInf.mark === undefined) ||
                        ((moves[j].from === this.bestMoveInf.move.from) &&
                        (moves[j].to === this.bestMoveInf.move.to) &&
                        (moves[j].figure === this.bestMoveInf.move.figure)))
                        {
                            this.bestMoveInf.move = bestMove;
                            this.bestMoveInf.mark = value;
                            this.bestMoveInf.depth = maxDepth;
                            this.bestMoveInf.progress = i + 1;
                            this.bestMoveInf.bestLine = Array.from(bestLine);
                            if (bestMove.from != bestLine[bestLine.length - 1].from)
                            {
                                let rrrr = 0;
                            }
                        }
                    
                }
            }
            
            result = value;
        }
        //#endregion
            else
        //#region минимизатор
        if (this.order === 1) {
            let value = marks[10];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            let i = 0;
            for( ; i < length; i++) {
                const move = moves[i];
                if (firstDepth) this.currentLine = this.getMoveNumber(move);

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                let ext = Math.max(beat, check);

                if (!ext)
                {
                    if (this.pruningHistory[move.from][move.to][move.figure].all >= maxDepth * maxDepth * 2)
                    {
                        let p = this.pruningHistory[move.from][move.to][move.figure].best / this.pruningHistory[move.from][move.to][move.figure].all;
                        ext = -1 / (100 * p + 0.5);
                    }
                    if (depth >= sortDepth) 
                    {
                        const records = this.hash.get(p);
                        let d = 0;
                        if (records)
                        for(let record of records)
                            if (record.depth > d) 
                                d = record.depth;
                        if (d >= 3)
                        {
                            ext -= i / length;
                        }
                    }
                }

                let res;
                if (i >= 1 && β - α > 1) {
                    let r = this.αβByTime(β - 1, β, depth - 1, extension + ext, maxDepth, p);
                    res = r.mark;
                    line = (r.line != undefined) ? r.line : [];
                    line.push(move);
                    if (res > α && res <= β - 1) 
                    {
                        r = this.αβByTime(α, res + 1, depth - 1, extension + ext, maxDepth, p);
                        res = r.mark;
                        line = (r.line != undefined) ? r.line : [];
                        line.push(move);
                    }
                } else {
                    let r = this.αβByTime(α, β, depth - 1, extension + ext, maxDepth, p);
                    res = r.mark;
                    line = (r.line != undefined) ? r.line : [];
                    line.push(move);
                }
                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                if (value > Math.min(value, res))
                {
                    value = Math.min(value, res);
                    bestLine = Array.from(line);
                }

                if (!beat && !check) this.pruningHistory[move.from][move.to][move.figure].all++;

                if (value < β) {
                    β = value;
                    bestMove = move;
                    isBestBeat = beat;
                    isBestCheck = check;
                }

                if (value <= α) {
                    //#region эвристика истории
                    if (!beat) this.history[move.from][move.to][move.figure] += depth * depth;
                    //#endregion
                    break;
                }

                if (bestMove && depth === maxDepth && (this.finish - performance.now() > 0 || maxDepth <= 1)) {
                    for (let j = 0; j <= i; j++)
                    if  ((this.bestMoveInf.mark === undefined) ||
                        ((moves[j].from === this.bestMoveInf.move.from) &&
                        (moves[j].to === this.bestMoveInf.move.to) &&
                        (moves[j].figure === this.bestMoveInf.move.figure)))
                        {
                            this.bestMoveInf.move = bestMove;
                            this.bestMoveInf.mark = value;
                            this.bestMoveInf.depth = maxDepth;
                            this.bestMoveInf.progress = i + 1;
                            this.bestMoveInf.bestLine = Array.from(bestLine);
                        }
                    
                }
            }

            result = value;
        }
        //#endregion

        //#region history pruning
        if (bestMove && !isBestBeat && !isBestCheck) this.pruningHistory[bestMove.from][bestMove.to][bestMove.figure].best++;
        //#endregion

        //#region заносим в хэш
        if (depth >= hashDepth && result !== drawMark) {
            this.addToHash(pos, oldα, oldβ, bestMove, result, depth);
        }
        //#endregion

        return { move: bestMove, mark: result, line: bestLine };
    }

    countLimit = 0;

    αβByCount(α, β, depth, extension, maxDepth, pos, firstDepth) {
        if (depth > 0 && maxDepth > 1 && this.countLimit - this.count <= 0) {
            if (this.order === 0) return { mark: +Infinity};
            return { mark: -Infinity};
        }

        if (this.count % 10000 == 0)
        self.postMessage(Math.floor(this.count * 100 / this.countLimit) + "%");

        const sortDepth = 2;
        const hashDepth = 2;
        const repetitionDepth = 2; // обязательно не больше hashDepth !!!
        const drawMark = -0.1;

        if (pos == null)
        pos = this.zobristHash();

        this.count++;

        function correctWinMark(value) {
            if (value > 0.9 * marks[10]) return --value;
            if (value < 0.9 * marks[11]) return ++value;
            return value;
        }

        let result;
        let bestMove, isActive;
        const [oldα, oldβ] = [α, β];

        //#region расчет глубины
        while (extension >= 1) {
            depth++;
            extension--;
        }

        while (extension <= -1) {
            depth = Math.max(0, depth - 1);
            extension++;
        }
        //#endregion

        //#region троекратное повторение
        if (depth >= repetitionDepth && depth != maxDepth) {
            const record = this.positionHistory.get(pos);
            if (record !== undefined && record >= 2) return { mark: drawMark };
        }
        //#endregion

        //#region смотрим в хэше
        if (depth >= hashDepth) {
            const res = this.seeHash(pos, α, β, depth);
            if (res && res.mark !== undefined) return res;
            if (res && res.newα !== undefined && !firstDepth) [α, β] = [res.newα, res.newβ];
        }
        //#endregion

        if (α < 0.9 * marks[11]) α = marks[11];
        if (β > 0.9 * marks[10]) β = marks[10];// фатовые оценки нельзя подрезать

        //#region null-pruning
        if (depth >= 1 && depth <= 1) {
            this.order ^= 1;
            let isNullPruning = false;
            let nullMark;
            if (this.order === 1 && β < +Infinity) {
                nullMark = this.αβByCount(β - 1, β, depth - 1, extension).mark;
                if (nullMark >= β) isNullPruning = true;
            }
                else
            if (this.order === 0 && α > -Infinity)
            {
                nullMark = this.αβByCount(α, α + 1, depth - 1, extension).mark;
                if (nullMark <= α) isNullPruning = true;
            }
            this.order ^= 1;
            if (isNullPruning) return { mark: nullMark };
        }
        //#endregion

        //#region выигрышная позиция
        const mark = this.winMark();
        if (mark !== false) {
            return { mark: mark };
        }
        //#endregion
            else
        //#region поверхностная оценка
        if (depth < 1) {
            const mark = this.quiesce2(α, β);
            result = mark;
        }
        //#endregion
            else
        //#region максимизатор
        if (this.order === 0) {
            let value = marks[11];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            let i = 0;
            for( ; i < length; i++) {
                const move = moves[i];
                if (firstDepth) this.currentLine = this.getMoveNumber(move);

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                let ext = Math.max(beat, check);

                if (!ext)
                {
                    if (this.pruningHistory[move.from][move.to][move.figure].all >= maxDepth * maxDepth * 2)
                    {
                        let p = this.pruningHistory[move.from][move.to][move.figure].best / this.pruningHistory[move.from][move.to][move.figure].all;
                        ext = -1 / (100 * p + 0.5);
                    }
                    if (depth >= sortDepth) 
                    {
                        const records = this.hash.get(p);
                        let d = 0;
                        if (records)
                        for(let record of records)
                            if (record.depth > d) 
                                d = record.depth;
                        if (d >= 3)
                        {
                            ext -= i / length;
                        }
                    }
                }

                let res;
                if (i >= 1 && β - α > 1) {
                    res = this.αβByCount(α, α + 1, depth - 1, extension + ext, maxDepth, p).mark;
                    if (res >= α + 1 && res < β) res = this.αβByCount(res - 1, β, depth - 1, extension + ext, maxDepth, p).mark;
                } else {
                    res = this.αβByCount(α, β, depth - 1, extension + ext, maxDepth, p).mark;
                }
                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                value = Math.max(value, res);

                if (!beat && !check) this.pruningHistory[move.from][move.to][move.figure].all++;

                if (value > α) {
                    α = value;
                    bestMove = move;
                    isActive = beat || check;
                }

                if (value >= β) {
                    //#region эвристика истории
                    if (!beat) this.history[move.from][move.to][move.figure] += depth * depth;
                    //#endregion
                    break;
                }

                if (firstDepth && bestMove && (this.countLimit - this.count > 0 || maxDepth <= 1)) {
                    for (let j = 0; j <= i; j++)
                    if  ((this.bestMoveInf.mark === undefined) ||
                        ((moves[j].from === this.bestMoveInf.move.from) &&
                        (moves[j].to === this.bestMoveInf.move.to) &&
                        (moves[j].figure === this.bestMoveInf.move.figure)))
                        {
                            this.bestMoveInf.move = bestMove;
                            this.bestMoveInf.mark = value;
                            this.bestMoveInf.depth = maxDepth;
                            this.bestMoveInf.progress = i + 1;
                        }
                    
                }
            }
            
            result = value;
        }
        //#endregion
            else
        //#region минимизатор
        if (this.order === 1) {
            let value = marks[10];

            const moves = this.getMoves();
            if (depth >= sortDepth) this.sortMoves(moves);

            const length = moves.length;
            let i = 0;
            for( ; i < length; i++) {
                const move = moves[i];
                if (firstDepth) this.currentLine = this.getMoveNumber(move);

                const beat = this.isBeat(move) ? 0.5 : 0;

                //#region PVS
                const p = this.recalculateZobristHash(pos, move);
                const argP = depth >= repetitionDepth ? p : undefined;

                this.moveByRules(move, argP);
                const check = this.isCheck() ? 0.5 : 0;
                let ext = Math.max(beat, check);

                if (!ext)
                {
                    if (this.pruningHistory[move.from][move.to][move.figure].all >= maxDepth * maxDepth * 2)
                    {
                        let p = this.pruningHistory[move.from][move.to][move.figure].best / this.pruningHistory[move.from][move.to][move.figure].all;
                        ext = -1 / (100 * p + 0.5);
                    }
                    if (depth >= sortDepth) 
                    {
                        const records = this.hash.get(p);
                        let d = 0;
                        if (records)
                        for(let record of records)
                            if (record.depth > d) 
                                d = record.depth;
                        if (d >= 3)
                        {
                            ext -= i / length;
                        }
                    }
                }

                let res;
                if (i >= 1 && β - α > 1) {
                    res = this.αβByCount(β - 1, β, depth - 1, extension + ext, maxDepth, p).mark;
                    if (res > α && res <= β - 1) res = this.αβByCount(α, res + 1, depth - 1, extension + ext, maxDepth, p).mark;
                } else {
                    res = this.αβByCount(α, β, depth - 1, extension + ext, maxDepth, p).mark;
                }
                res = correctWinMark(res);
                this.unmoveByRules(argP);
                //#endregion

                value = Math.min(value, res); 

                if (!beat && !check) this.pruningHistory[move.from][move.to][move.figure].all++;

                if (value < β) {
                    β = value;
                    bestMove = move;
                    isActive = beat || check;
                }

                if (value <= α) {
                    //#region эвристика истории
                    if (!beat) this.history[move.from][move.to][move.figure] += depth * depth;
                    //#endregion
                    break;
                }

                if (firstDepth && bestMove && (this.finish - performance.now() > 0 || maxDepth <= 1)) {
                    for (let j = 0; j <= i; j++)
                    if  ((this.bestMoveInf.mark === undefined) ||
                        ((moves[j].from === this.bestMoveInf.move.from) &&
                        (moves[j].to === this.bestMoveInf.move.to) &&
                        (moves[j].figure === this.bestMoveInf.move.figure)))
                        {
                            this.bestMoveInf.move = bestMove;
                            this.bestMoveInf.mark = value;
                            this.bestMoveInf.depth = maxDepth;
                            this.bestMoveInf.progress = i + 1;
                        }
                    
                }
            }

            result = value;
        }
        //#endregion

        //#region history pruning
        if (bestMove && !isActive) this.pruningHistory[bestMove.from][bestMove.to][bestMove.figure].best++;
        //#endregion

        //#region заносим в хэш
        if (depth >= hashDepth && result !== drawMark) {
            this.addToHash(pos, oldα, oldβ, bestMove, result, depth);
        }
        //#endregion

        return { move: bestMove, mark: result };
    }

    IDS(depth) {
        const point = marks[0] / 100;
        const pos = this.zobristHash();
        let res;
        let hypothesis = 0;
        for(let i = 0; i <= depth; i++) {
            const lastMoveOrder = (this.order + i + 1) % 2;
            let α, β;
            if (lastMoveOrder === 0) [α, β] = [hypothesis - 10 * point, hypothesis + 20 * point]; else
                                     [α, β] = [hypothesis - 20 * point, hypothesis + 10 * point];
            res = this.αβ(α, β, i, 0, i, pos);

            if (res.mark <= α) res = this.αβ(-Infinity, α + 1, i, 0, i, pos, true); else 
            if (res.mark >= β) res = this.αβ(β - 1, +Infinity, i, 0, i, pos, true);

            hypothesis = res.mark;
        }

        if (!res.move) res = this.αβ(-Infinity, +Infinity, depth, 0, depth, pos); // НА ЭКСТРЕННЫЙ СЛУЧАЙ
        return res;
    }

    cleanIDS(depth) {
        const point = marks[0] / 100;
        const pos = this.zobristHash();
        let res;
        let hypothesis = 0;
        for(let i = 0; i <= depth; i++) {
            const lastMoveOrder = (this.order + i + 1) % 2;
            let α, β;
            if (lastMoveOrder === 0) [α, β] = [hypothesis - 10 * point, hypothesis + 20 * point]; else
                                     [α, β] = [hypothesis - 20 * point, hypothesis + 10 * point];
            res = this.αβ(α, β, i, 0, i, pos);

            if (res.mark <= α) res = this.cleanαβ(-Infinity, α + 1, i, 0, i, pos); else 
            if (res.mark >= β) res = this.cleanαβ(β - 1, +Infinity, i, 0, i, pos);

            hypothesis = res.mark;
        }

        if (!res.move) res = this.αβ(-Infinity, +Infinity, depth, 0, depth, pos); // НА ЭКСТРЕННЫЙ СЛУЧАЙ
        return res;
    }

    variability = 0;
    variabilityArray = {};
    currentLine = 0;
    initializeVariability()
    {
        let moves = this.getMoves();
        for (let i = 0; i < moves.length; i++)
        this.variabilityArray[i] = Math.round((Math.random() - 0.5) * 2 * this.variability);
    }

    getMoveNumber(move)
    {
        let moves = this.getMoves();
        for (let i = 0; i < moves.length; i++)
        {
            let m = moves[i];
            if (m.from === move.from && m.to === move.to && m.figure === move.figure)
            return i;
        }
        return undefined;
    }

    bestMove(depth) {
        this.hash = new Map();
        this.initializeHistory();
        this.initializePruningHistory();

        this.variability = 0;
        this.initializeVariability();

        const res = this.IDS(depth);
        const move = res.move;
        console.log(`${ntof(move.figure)} ${ntoc(move.from)} ${ntoc(move.to)} ${res.mark}`);
        return res;
    }

    cleanBestMove(depth) {
        this.hash = new Map();
        this.initializeHistory();
        this.initializePruningHistory();

        this.variability = 0;
        this.initializeVariability();

        const res = this.cleanIDS(depth);

        const move = res.move;
        //console.log(`${ntof(move.figure)} ${ntoc(move.from)} ${ntoc(move.to)} ${res.mark}`);
        return res;
    }

    bestMoveByTime(time) {
        this.initializeVariability();
        this.hash = new Map();
        this.initializeHistory();
        this.initializePruningHistory();
        const pos = this.zobristHash();

        
        
        const point = marks[0] / 100;
        let res;
        let hypothesis = 0;
        let i = 1;
        this.finish = performance.now() + time;
        while (this.finish - performance.now() > 0) {
            const lastMoveOrder = (this.order + i + 1) % 2;
            let α, β;
            if (lastMoveOrder === 0) [α, β] = [hypothesis - 10 * point, hypothesis + 20 * point]; else
                                     [α, β] = [hypothesis - 20 * point, hypothesis + 10 * point];
            res = this.αβByTime(α, β, i, 0, i, pos, true);

            if (res.mark <= α) res = this.αβByTime(-Infinity, α + 1, i, 0, i, pos, true); else 
            if (res.mark >= β) res = this.αβByTime(β - 1, +Infinity, i, 0, i, pos, true);

            hypothesis = res.mark;
            if (!res.move) res = this.αβByTime(-Infinity, +Infinity, i, 0, i, pos, true);

            if (this.finish - performance.now() > 0 || i === 1) {
                this.bestMoveInf.move = res.move;
                this.bestMoveInf.mark = res.mark;
                this.bestMoveInf.depth = i;
                this.bestMoveInf.progress = this.getMoves().length;
            }

            self.postMessage(this.bestMoveInf);

            const move = this.bestMoveInf.move;
            const progress = this.bestMoveInf.progress;
            const depth = this.bestMoveInf.depth;
            const all = this.getMoves().length;
            const mark = this.bestMoveInf.mark;
            console.log(`${depth}) ${progress}/${all} ${ntof(move.figure)} ${ntoc(move.from)} ${ntoc(move.to)} ${mark}`);
            console.log(`Позиций: ${this.count}`);
            i++;
        }

        


        return this.bestMoveInf;
        
    }

    bestMoveByCount(limit) {
        this.initializeVariability();
        this.hash = new Map();
        this.initializeHistory();
        this.initializePruningHistory();
        const pos = this.zobristHash();

        
        
        const point = marks[0] / 100;
        let res;
        let hypothesis = 0;
        let i = 1;
        this.countLimit = limit;
        this.count = 0;

        while (this.countLimit - this.count > 0) {
            const lastMoveOrder = (this.order + i + 1) % 2;
            let α, β;
            if (lastMoveOrder === 0) [α, β] = [hypothesis - 10 * point, hypothesis + 20 * point]; else
                                     [α, β] = [hypothesis - 20 * point, hypothesis + 10 * point];
            res = this.αβByCount(α, β, i, 0, i, pos, true);

            if (res.mark <= α) res = this.αβByCount(-Infinity, α + 1, i, 0, i, pos, true); else 
            if (res.mark >= β) res = this.αβByCount(β - 1, +Infinity, i, 0, i, pos, true);

            hypothesis = res.mark;
            if (!res.move) res = this.αβByCount(-Infinity, +Infinity, i, 0, i, pos, true);

            if (this.countLimit - this.count > 0 || i === 1) {
                this.bestMoveInf.move = res.move;
                this.bestMoveInf.mark = res.mark;
                this.bestMoveInf.depth = i;
                this.bestMoveInf.progress = this.getMoves().length;
            }

            const move = this.bestMoveInf.move;
            const progress = this.bestMoveInf.progress;
            const depth = this.bestMoveInf.depth;
            const all = this.getMoves().length;
            const mark = this.bestMoveInf.mark;
            console.log(`${depth}) ${progress}/${all} ${ntof(move.figure)} ${ntoc(move.from)} ${ntoc(move.to)} ${mark}`);
            //console.log(`Позиций: ${this.count}`);
            i++;
        }

        return this.bestMoveInf;
        
    }

    bestMoveByLevel(level)
    {
        global.onmessage({data: "get"});
        let limit;
        switch (level)
        {
            case 0: {limit =  3000; this.variability = 500} break;
            case 1: {limit =  10000; this.variability = 250} break;
            case 2: {limit =  30000; this.variability = 100} break;
            case 3: {limit =  100000; this.variability = 50} break;
            case 4: {limit =  300000; this.variability = 25} break;
            case 5: {limit =  1000000; this.variability = 20} break;
            case 6: {limit =  3000000; this.variability = 15} break;
            case 7: {limit =  10000000; this.variability = 15} break;
            case 8: {limit =  30000000; this.variability = 10} break;
            case 9: {limit =  70000000; this.variability = 10} break;
            case 10: {limit = 150000000; this.variability = 8} break;
        }

        return this.bestMoveByCount(limit);
    }
}

