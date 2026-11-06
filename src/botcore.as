// ===== GopBot core (valid AS2 and plain JS) =====
_global.GopBot = {};
var GB = _global.GopBot;


GB.straightHigh = function(a) {
    var run = 0;
    for (var x = 14; x >= 1; x--) {
        var p = (x == 1) ? a[14] : a[x];
        if (p > 0) {
            run++;
            if (run == 5) { return x + 4; }
        } else {
            run = 0;
        }
    }
    return 0;
};

GB.top = function(cnt, ex1, ex2, k) {
    var r = [];
    for (var x = 14; x >= 2 && r.length < k; x--) {
        if (cnt[x] > 0 && x != ex1 && x != ex2) { r.push(x); }
    }
    while (r.length < k) { r.push(0); }
    return r;
};

// v = values 2..14, s = suits 0..3, n cards (5..7). Higher score wins.
GB.eval7 = function(v, s, n) {
    var B = 759375;
    var cnt = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    var sc = [0,0,0,0];
    var i;
    var x;
    var r;
    for (i = 0; i < n; i++) { cnt[v[i]]++; sc[s[i]]++; }
    var fs = -1;
    for (i = 0; i < 4; i++) { if (sc[i] >= 5) { fs = i; } }
    if (fs >= 0) {
        var fc = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        for (i = 0; i < n; i++) { if (s[i] == fs) { fc[v[i]] = 1; } }
        var sh = GB.straightHigh(fc);
        if (sh > 0) { return 8 * B + sh * 50625; }
        r = GB.top(fc, 0, 0, 5);
        return 5 * B + r[0] * 50625 + r[1] * 3375 + r[2] * 225 + r[3] * 15 + r[4];
    }
    var quad = 0;
    var trips = [];
    var pairs = [];
    for (x = 14; x >= 2; x--) {
        var c = cnt[x];
        if (c == 4) { quad = x; }
        else if (c == 3) { trips.push(x); }
        else if (c == 2) { pairs.push(x); }
    }
    if (quad > 0) {
        r = GB.top(cnt, quad, 0, 1);
        return 7 * B + quad * 50625 + r[0] * 3375;
    }
    if (trips.length >= 1 && (trips.length >= 2 || pairs.length >= 1)) {
        var p2 = 0;
        if (trips.length >= 2) { p2 = trips[1]; }
        if (pairs.length >= 1 && pairs[0] > p2) { p2 = pairs[0]; }
        return 6 * B + trips[0] * 50625 + p2 * 3375;
    }
    var hi = GB.straightHigh(cnt);
    if (hi > 0) { return 4 * B + hi * 50625; }
    if (trips.length >= 1) {
        r = GB.top(cnt, trips[0], 0, 2);
        return 3 * B + trips[0] * 50625 + r[0] * 3375 + r[1] * 225;
    }
    if (pairs.length >= 2) {
        r = GB.top(cnt, pairs[0], pairs[1], 1);
        return 2 * B + pairs[0] * 50625 + pairs[1] * 3375 + r[0] * 225;
    }
    if (pairs.length == 1) {
        r = GB.top(cnt, pairs[0], 0, 3);
        return 1 * B + pairs[0] * 50625 + r[0] * 3375 + r[1] * 225 + r[2] * 15;
    }
    r = GB.top(cnt, 0, 0, 5);
    return r[0] * 50625 + r[1] * 3375 + r[2] * 225 + r[3] * 15 + r[4];
};

// Monte Carlo equity. myV/myS: 2 hole cards. boardV/boardS: 0..5 known board cards.
// nOpp: opponents still in. kk: >1 means one opponent is "the aggressor" and is sampled
// best-of-kk (a stronger-than-random range). iters: sample count.
GB.equity = function(myV, myS, boardV, boardS, nOpp, kk, iters) {
    if (nOpp < 1) { return 1; }
    var dv = [];
    var ds = [];
    var su;
    var va;
    var q;
    var bad;
    for (su = 0; su < 4; su++) {
        for (va = 2; va <= 14; va++) {
            bad = false;
            for (q = 0; q < 2; q++) { if (myV[q] == va && myS[q] == su) { bad = true; } }
            for (q = 0; q < boardV.length; q++) { if (boardV[q] == va && boardS[q] == su) { bad = true; } }
            if (!bad) { dv.push(va); ds.push(su); }
        }
    }
    var m = dv.length;
    var miss = 5 - boardV.length;
    var raiser = (kk > 1) ? 1 : 0;
    var plain = nOpp - raiser;
    var need = miss + 2 * plain + 2 * (raiser ? kk : 0);
    if (need > m) { return 0.5; }
    var tv = [0,0,0,0,0,0,0];
    var ts = [0,0,0,0,0,0,0];
    var total = 0;
    var it;
    var i;
    var j;
    var t;
    var idx;
    var mine;
    var best;
    var tie;
    var lost;
    var sc;
    var o;
    var g;
    for (it = 0; it < iters; it++) {
        for (i = 0; i < need; i++) {
            j = i + Math.floor(Math.random() * (m - i));
            t = dv[i]; dv[i] = dv[j]; dv[j] = t;
            t = ds[i]; ds[i] = ds[j]; ds[j] = t;
        }
        for (i = 0; i < boardV.length; i++) { tv[2 + i] = boardV[i]; ts[2 + i] = boardS[i]; }
        for (i = 0; i < miss; i++) { tv[2 + boardV.length + i] = dv[i]; ts[2 + boardV.length + i] = ds[i]; }
        tv[0] = myV[0]; ts[0] = myS[0]; tv[1] = myV[1]; ts[1] = myS[1];
        mine = GB.eval7(tv, ts, 7);
        idx = miss;
        tie = 0; lost = false;
        for (o = 0; o < plain; o++) {
            tv[0] = dv[idx]; ts[0] = ds[idx]; tv[1] = dv[idx + 1]; ts[1] = ds[idx + 1];
            idx += 2;
            sc = GB.eval7(tv, ts, 7);
            if (sc > mine) { lost = true; break; }
            if (sc == mine) { tie++; }
        }
        if (!lost && raiser) {
            best = -1;
            for (g = 0; g < kk; g++) {
                tv[0] = dv[idx]; ts[0] = ds[idx]; tv[1] = dv[idx + 1]; ts[1] = ds[idx + 1];
                idx += 2;
                sc = GB.eval7(tv, ts, 7);
                if (sc > best) { best = sc; }
            }
            if (best > mine) { lost = true; }
            else if (best == mine) { tie++; }
        }
        if (!lost) { total += 1 / (tie + 1); }
    }
    return total / iters;
};


// Equity when opponents' hole cards are KNOWN. oppV/oppS: arrays of [v1,v2] / [s1,s2].
GB.equityKnown = function(myV, myS, boardV, boardS, oppV, oppS, iters) {
    var dv = [];
    var ds = [];
    var su;
    var va;
    var q;
    var o;
    var bad;
    for (su = 0; su < 4; su++) {
        for (va = 2; va <= 14; va++) {
            bad = false;
            for (q = 0; q < 2; q++) { if (myV[q] == va && myS[q] == su) { bad = true; } }
            for (q = 0; q < boardV.length; q++) { if (boardV[q] == va && boardS[q] == su) { bad = true; } }
            for (o = 0; o < oppV.length; o++) {
                for (q = 0; q < 2; q++) { if (oppV[o][q] == va && oppS[o][q] == su) { bad = true; } }
            }
            if (!bad) { dv.push(va); ds.push(su); }
        }
    }
    var m = dv.length;
    var miss = 5 - boardV.length;
    if (miss == 0) { iters = 1; }
    var tv = [0,0,0,0,0,0,0];
    var ts = [0,0,0,0,0,0,0];
    var total = 0;
    var it;
    var i;
    var j;
    var t;
    var mine;
    var tie;
    var lost;
    var sc;
    for (it = 0; it < iters; it++) {
        for (i = 0; i < miss; i++) {
            j = i + Math.floor(Math.random() * (m - i));
            t = dv[i]; dv[i] = dv[j]; dv[j] = t;
            t = ds[i]; ds[i] = ds[j]; ds[j] = t;
        }
        for (i = 0; i < boardV.length; i++) { tv[2 + i] = boardV[i]; ts[2 + i] = boardS[i]; }
        for (i = 0; i < miss; i++) { tv[2 + boardV.length + i] = dv[i]; ts[2 + boardV.length + i] = ds[i]; }
        tv[0] = myV[0]; ts[0] = myS[0]; tv[1] = myV[1]; ts[1] = myS[1];
        mine = GB.eval7(tv, ts, 7);
        tie = 0;
        lost = false;
        for (o = 0; o < oppV.length; o++) {
            tv[0] = oppV[o][0]; ts[0] = oppS[o][0]; tv[1] = oppV[o][1]; ts[1] = oppS[o][1];
            sc = GB.eval7(tv, ts, 7);
            if (sc > mine) { lost = true; break; }
            if (sc == mine) { tie++; }
        }
        if (!lost) { total += 1 / (tie + 1); }
    }
    return total / iters;
};


// Does this hole-card pair + visible board look "strong enough to call big bets" to the AI?
GB.oppIsStrong = function(oV, oS, bV, bS) {
    if (bV.length == 0) {
        return (oV[0] == oV[1]) || (oV[0] >= 10 && oV[1] >= 10);
    }
    var tv = [oV[0], oV[1]];
    var ts = [oS[0], oS[1]];
    for (var i = 0; i < bV.length; i++) { tv.push(bV[i]); ts.push(bS[i]); }
    if (tv.length < 5) { return false; }
    var sc = GB.eval7(tv, ts, tv.length);
    var cat = Math.floor(sc / 759375);
    if (cat >= 2) { return true; }
    if (cat == 1) {
        var pv = Math.floor((sc - 759375) / 50625);
        return pv >= 10;
    }
    return false;
};


// Stack the deck: d = shuffled deck (objects with cardValue/cardColor), seats = filledSeats,
// me = our seat id. Seat index k is dealt d[2k], d[2k+1]; board = d[2n .. 2n+4].
// Gives our seat the best final 7-card hand by swapping hole cards with the current best seat.
GB.stack = function(d, seats, me) {
    var n = seats.length;
    var mi = -1;
    var k;
    var t;
    for (k = 0; k < n; k++) { if (seats[k] == me) { mi = k; } }
    if (mi < 0 || n < 2 || d.length < 2 * n + 5) { return false; }
    var bv = [];
    var bs = [];
    for (t = 0; t < 5; t++) { bv.push(d[2 * n + t].cardValue); bs.push(d[2 * n + t].cardColor); }
    var tv = [0, 0, bv[0], bv[1], bv[2], bv[3], bv[4]];
    var ts = [0, 0, bs[0], bs[1], bs[2], bs[3], bs[4]];
    var best = -1;
    var bi = -1;
    var mine = -1;
    var sc;
    for (k = 0; k < n; k++) {
        tv[0] = d[2 * k].cardValue; ts[0] = d[2 * k].cardColor;
        tv[1] = d[2 * k + 1].cardValue; ts[1] = d[2 * k + 1].cardColor;
        sc = GB.eval7(tv, ts, 7);
        if (k == mi) { mine = sc; }
        if (sc > best) { best = sc; bi = k; }
    }
    if (mine >= best || bi < 0) { return true; }
    t = d[2 * mi]; d[2 * mi] = d[2 * bi]; d[2 * bi] = t;
    t = d[2 * mi + 1]; d[2 * mi + 1] = d[2 * bi + 1]; d[2 * bi + 1] = t;
    return true;
};

// Pure decision. s = {toCall, minBet, pot, stack, bigBlind, unit, nOpp, state, equity,
// raisesThisStreet, myHasBetThisStreet}. Returns {action, amount}.
GB.choose = function(s) {
    var eq = s.equity;
    var toCall = s.toCall;
    var stack = s.stack;
    var pot = s.pot;
    var nOpp = s.nOpp;
    var minInc = Math.max(s.minBet, s.bigBlind);
    var unit = Math.max(1, s.unit);
    var strongT = s.exact ? 0.6 : Math.min(0.80, 0.56 + 0.04 * (nOpp - 1));
    var river = (s.state == "river");
    var margin = s.exact ? 0.005 : (river ? 0.02 : 0.04);
    var raiseTotal = function(frac) {
        var base = pot + toCall;
        var inc = Math.max(minInc, frac * base);
        var tot = toCall + inc;
        tot = Math.round(tot / unit) * unit;
        if (tot < toCall + minInc) { tot = toCall + minInc; }
        if (tot >= stack * 0.7) { tot = stack; }
        return Math.min(tot, stack);
    };
    var amt;
    if (s.exact) {
        if (eq > 0.5) {
            if (stack <= toCall) { return { action: "call", amount: stack }; }
            if (toCall <= 0) {
                var f0 = s.oppStrong ? 1.0 : (river ? 0.6 : (s.state == "preflop" ? 0.35 : 0.4));
                return { action: "raise", amount: raiseTotal(f0) };
            }
            if (s.raisesThisStreet < 2 && Math.random() < (s.oppStrong ? 0.8 : 0.15)) {
                var f1 = s.oppStrong ? 1.0 : (river ? 0.6 : 0.4);
                amt = raiseTotal(f1);
                if (amt > toCall) { return { action: "raise", amount: amt }; }
            }
            return { action: "call", amount: toCall };
        }
        if (toCall <= 0) { return { action: "check", amount: 0 }; }
        return { action: "fold", amount: 0 };
    }
    if (toCall <= 0) {
        if (s.exact && eq > 0.92 && (s.state == "flop" || s.state == "turn" || (s.state == "preflop" && nOpp >= 2)) && Math.random() < 0.45) {
            return { action: "check", amount: 0 };
        }
        if (s.exact && eq > strongT) {
            amt = raiseTotal(river ? 0.55 : (eq > 0.85 ? 0.4 : 0.33));
            return { action: "raise", amount: amt };
        }
        if (eq > strongT) {
            amt = raiseTotal(eq > 0.95 ? 1.0 : (eq > 0.85 ? 0.85 : (eq > 0.72 ? 0.65 : 0.5)));
            return { action: "raise", amount: amt };
        }
        if (!s.exact && (s.state == "flop" || s.state == "turn") && nOpp <= 2 && eq > 0.28 && eq < 0.48 && Math.random() < 0.22) {
            return { action: "raise", amount: raiseTotal(0.6) };
        }
        if (!s.exact && s.state == "preflop" && nOpp <= 3 && eq > 0.36 && Math.random() < 0.15) {
            return { action: "raise", amount: raiseTotal(0.8) };
        }
        return { action: "check", amount: 0 };
    }
    var need = toCall / (pot + toCall);
    if (toCall >= stack) {
        if (eq > need + 0.03) { return { action: "call", amount: stack }; }
        return { action: "fold", amount: 0 };
    }
    if (s.exact && eq > 0.92 && !river && Math.random() < 0.55) {
        return { action: "call", amount: toCall };
    }
    if (s.exact && eq > strongT + 0.06 && s.raisesThisStreet < 2) {
        amt = raiseTotal(river ? 0.6 : 0.4);
        if (amt > toCall) { return { action: "raise", amount: amt }; }
    }
    if (eq > strongT + 0.06 && (s.raisesThisStreet < 3 || eq > 0.9)) {
        amt = raiseTotal(eq > 0.88 ? 1.0 : 0.7);
        if (amt > toCall) { return { action: "raise", amount: amt }; }
    }
    if (eq > need + margin) { return { action: "call", amount: toCall }; }
    return { action: "fold", amount: 0 };
};
