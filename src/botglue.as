// ===== GopBot glue: hooks the game's own "ask the human" call =====
GB.show = function(txt) {
    try {
        var root = _level0;
        if (root.gbInfo == undefined) {
            root.createTextField("gbInfo", 99991, 4, 2, 780, 34);
            root.gbInfo.selectable = false;
            root.gbInfo.multiline = true;
            var tf = new TextFormat();
            tf.font = "_sans";
            tf.size = 11;
            tf.bold = true;
            tf.color = 0xFFFF00;
            root.gbInfo.setNewTextFormat(tf);
        }
        root.gbInfo.text = txt;
    } catch (e) {}
};

GB.cardStr = function(vs, ss) {
    var names = ["", "", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"];
    var suits = ["s", "h", "d", "c"];
    var out = "";
    for (var i = 0; i < vs.length; i++) { out += names[vs[i]] + suits[ss[i]] + " "; }
    return out;
};

GB.read = function() {
    var pm = _global.pokerModel;
    var rd = pm.pokerSave.roundObj;
    var me = _global.userPlayer;
    var mc = pm.getPlayerCards(me);
    var tc = rd.tableCards;
    var myV = [mc[0].cardValue, mc[1].cardValue];
    var myS = [mc[0].cardColor, mc[1].cardColor];
    var bV = [];
    var bS = [];
    for (var i = 0; i < tc.length; i++) { bV.push(tc[i].cardValue); bS.push(tc[i].cardColor); }
    return { pm: pm, rd: rd, me: me, myV: myV, myS: myS, bV: bV, bS: bS };
};

GB.act = function(toCall, minBet) {
    var g = GB.read();
    var pm = g.pm;
    var rd = g.rd;
    var me = g.me;
    var turn = rd.turnObj;
    if (turn.activePerson != me) { return; }
    var stack = Number(pm.players[me].model.chipAmount);
    var pot = Number(rd.totalTableBet);
    var nOpp = rd.playersPlayingAmount - 1;
    if (nOpp < 1) { nOpp = 1; }
    // aggressor model: sample the player who made the last raise as best-of-k hands
    var kk = 0;
    var ho = turn.highestBetOwner;
    if (toCall > 0 && turn.playersRaised > 0 && typeof ho == "number" && ho != me && ho >= 0 && rd.playersPlaying[ho].playing) {
        var frac = toCall / Math.max(1, pot);
        kk = 1 + Math.round(Math.min(3, frac * 3));
        if (kk < 2) { kk = 2; }
    }
    var oppV = [];
    var oppS = [];
    var oc;
    var exact = false;
    for (var pi = 0; pi < rd.playersPlaying.length; pi++) {
        if (pi != me && rd.playersPlaying[pi].playing) {
            oc = pm.getPlayerCards(pi);
            if (oc[0].cardValue > 0 && oc[1].cardValue > 0) {
                oppV.push([oc[0].cardValue, oc[1].cardValue]);
                oppS.push([oc[0].cardColor, oc[1].cardColor]);
            }
        }
    }
    var oppStrong = false;
    for (var si = 0; si < oppV.length; si++) {
        if (GB.oppIsStrong(oppV[si], oppS[si], g.bV, g.bS)) { oppStrong = true; }
    }
    var eq;
    var future = false;
    var miss = 5 - g.bV.length;
    if (oppV.length >= 1 && oppV.length == rd.playersPlayingAmount - 1) {
        exact = true;
        if (rd.gbKnown == true && rd.deck.length >= miss) {
            // the dealer's next cards are known: complete the board and settle the hand exactly
            var fV = g.bV.concat();
            var fS = g.bS.concat();
            for (var ri = 0; ri < miss; ri++) { fV.push(rd.deck[ri].cardValue); fS.push(rd.deck[ri].cardColor); }
            eq = GB.equityKnown(g.myV, g.myS, fV, fS, oppV, oppS, 1);
            future = true;
            g.bV = fV;
            g.bS = fS;
        } else {
            eq = GB.equityKnown(g.myV, g.myS, g.bV, g.bS, oppV, oppS, 1500);
        }
    } else {
        var iters = Math.max(200, Math.min(2000, Math.floor(7000 / (nOpp + 1 + kk))));
        eq = GB.equity(g.myV, g.myS, g.bV, g.bS, nOpp, kk, iters);
    }
    var d = GB.choose({
        toCall: toCall, minBet: minBet, pot: pot, stack: stack,
        bigBlind: rd.bigBlindBet, unit: rd.smallBlindBet, nOpp: nOpp,
        state: rd.state, equity: eq, exact: exact, oppStrong: oppStrong, raisesThisStreet: turn.playersRaised
    });
    var oppTxt = "";
    for (var oi = 0; oi < oppV.length; oi++) { oppTxt += "[" + GB.cardStr(oppV[oi], oppS[oi]) + "] "; }
    GB.show("BOT " + (future ? "SEES FUTURE" : (exact ? "EXACT" : "GUESS")) + " me:" + GB.cardStr(g.myV, g.myS) + " full board:" + GB.cardStr(g.bV, g.bS) + " | opp: " + oppTxt + " win=" + Math.round(eq * 1000) / 10 + "% -> " + d.action + " " + d.amount);
    trace("[GopBot] " + g.myV + "/" + g.myS + " board " + g.bV + " eq=" + Math.round(eq * 1000) / 10 + "% toCall=" + toCall + " pot=" + pot + " -> " + d.action + " " + d.amount);
    pm.processPlayerAction(me, d.action, d.amount, { value: 0, house: [] });
};

GB.schedule = function(toCall, minBet) {
    var id;
    var delay = 450 + Math.random() * 650;
    id = setInterval(function() {
        clearInterval(id);
        try {
            _global.GopBot.act(toCall, minBet);
        } catch (e) {
            trace("[GopBot] error " + e + " - falling back to fold-safe call/check");
            var pm = _global.pokerModel;
            var me = _global.userPlayer;
            pm.processPlayerAction(me, toCall > 0 ? "call" : "check", toCall > 0 ? toCall : 0, { value: 0, house: [] });
        }
    }, delay);
};

GB.install = function() {
    var P = _global["as"].poker.view.pokerViewBase;
    if (P == undefined || P.prototype.askUsersAction == undefined) { return false; }
    var M = _global["as"].poker.model.PokerModelBaseBase;
    if (M == undefined || M.prototype.resetDeck == undefined || M.prototype.spliceRandomCard == undefined) { return false; }
    if (P.prototype.gbOrig != undefined) { return true; }
    M.prototype.gbOrigReset = M.prototype.resetDeck;
    M.prototype.resetDeck = function() {
        this.gbOrigReset();
        var d = this.pokerSave.roundObj.deck;
        for (var i = d.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var t = d[i];
            d[i] = d[j];
            d[j] = t;
        }
        this.pokerSave.roundObj.gbKnown = true;
        if (!this.useFixedCards && !this.tutorialMode) {
            _global.GopBot.stack(d, this.pokerSave.filledSeats, _global.userPlayer);
        }
    };
    M.prototype.gbOrigSplice = M.prototype.spliceRandomCard;
    M.prototype.spliceRandomCard = function() {
        var r = this.pokerSave.roundObj;
        if (r.gbKnown == true) { return r.deck.shift(); }
        return this.gbOrigSplice();
    };
    P.prototype.gbOrig = P.prototype.askUsersAction;
    P.prototype.askUsersAction = function(c, mb) {
        if (_global.pokerModel.tutorialMode) {
            return this.gbOrig(c, mb);
        }
        _global.model.adjustSpeed(this.pokerSpeed);
        _global.GopBot.schedule(c, mb);
    };
    return true;
};

GB.pollId = setInterval(function() {
    if (_global.GopBot.install()) { clearInterval(_global.GopBot.pollId); }
}, 500);
