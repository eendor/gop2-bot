var _global={}; 
eval(require('fs').readFileSync(__dirname+'/../src/botcore.as','utf8')+';globalThis.GB=GB;');
const E=(h)=>{const v=h.map(c=>c[0]),s=h.map(c=>c[1]);return GB.eval7(v,s,h.length)};
// [value,suit]
const T=(name,a,b)=>console.log(name, E(a)>E(b)?'OK':'FAIL');
T('SF>quads',[[10,0],[11,0],[12,0],[13,0],[14,0],[2,1],[3,2]],[[9,0],[9,1],[9,2],[9,3],[2,0],[3,1],[4,2]]);
T('quads>FH',[[9,0],[9,1],[9,2],[9,3],[2,0],[3,1],[4,2]],[[9,0],[9,1],[9,2],[5,3],[5,0],[3,1],[4,2]]);
T('FH>flush',[[9,0],[9,1],[9,2],[5,3],[5,0],[3,1],[4,2]],[[2,0],[5,0],[7,0],[9,0],[11,0],[3,1],[4,2]]);
T('flush>straight',[[2,0],[5,0],[7,0],[9,0],[11,0],[3,1],[4,2]],[[5,0],[6,1],[7,2],[8,3],[9,0],[2,1],[3,2]]);
T('wheel<6high straight',[[6,0],[5,1],[4,2],[3,3],[2,0],[9,1],[13,2]],[[14,0],[2,1],[3,2],[4,3],[5,0],[9,1],[13,2]]);
T('straight>trips',[[5,0],[6,1],[7,2],[8,3],[9,0],[2,1],[3,2]],[[7,0],[7,1],[7,2],[8,3],[12,0],[2,1],[3,2]]);
T('trips>2pair',[[7,0],[7,1],[7,2],[8,3],[12,0],[2,1],[3,2]],[[7,0],[7,1],[8,2],[8,3],[12,0],[2,1],[3,2]]);
T('2pair>pair',[[7,0],[7,1],[8,2],[8,3],[12,0],[2,1],[3,2]],[[7,0],[7,1],[8,2],[10,3],[12,0],[2,1],[3,2]]);
T('pair>high',[[7,0],[7,1],[8,2],[10,3],[12,0],[2,1],[3,2]],[[14,0],[13,1],[8,2],[10,3],[12,0],[2,1],[3,2]]);
T('kicker',[[7,0],[7,1],[14,2],[10,3],[12,0],[2,1],[3,2]],[[7,2],[7,3],[13,2],[10,1],[12,1],[2,3],[3,3]]);
T('2 trips FH',[[7,0],[7,1],[7,2],[8,3],[8,0],[8,1],[3,2]],[[7,0],[7,1],[7,2],[2,3],[2,0],[9,1],[3,2]]);
const eq=(a,b,bd,n,kk,it)=>GB.equity(a.map(c=>c[0]),a.map(c=>c[1]),bd.map(c=>c[0]),bd.map(c=>c[1]),n,kk,it);
console.log('AA vs 1 random (expect ~0.85):',eq([[14,0],[14,1]],0,[],1,0,20000).toFixed(3));
console.log('AA vs 8 random (expect ~0.35):',eq([[14,0],[14,1]],0,[],8,0,20000).toFixed(3));
console.log('72o vs 1 random (expect ~0.35):',eq([[7,0],[2,1]],0,[],1,0,20000).toFixed(3));
console.log('AKs vs 1 random (expect ~0.67):',eq([[14,0],[13,0]],0,[],1,0,20000).toFixed(3));
console.log('nut flush draw flop vs 1 (expect ~0.62-0.65):',eq([[14,0],[9,0]],0,[[2,0],[7,0],[12,1]],1,0,20000).toFixed(3));
let t=Date.now(); eq([[14,0],[9,0]],0,[],8,3,1000); console.log('1000 iters x 8 opp ms:',Date.now()-t);
const ek=(a,o,bd,it)=>GB.equityKnown(a.map(c=>c[0]),a.map(c=>c[1]),bd.map(c=>c[0]),bd.map(c=>c[1]),o.map(h=>h.map(c=>c[0])),o.map(h=>h.map(c=>c[1])),it);
console.log('AA vs KK preflop (expect ~0.82):',ek([[14,0],[14,1]],[[[13,2],[13,3]]],[],20000).toFixed(3));
console.log('AA vs 22 on K22 flop (expect ~0.04... AA drawing):',ek([[14,0],[14,1]],[[[2,2],[2,3]]],[[13,0],[2,1],[5,2]],5000).toFixed(3));
console.log('river exact win:',ek([[14,0],[14,1]],[[[13,2],[13,3]]],[[2,0],[7,1],[9,2],[3,3],[12,1]],1));
const ch=(o)=>GB.choose(Object.assign({toCall:20,minBet:20,pot:100,stack:1000,bigBlind:20,unit:10,nOpp:2,state:'flop',equity:0.7,raisesThisStreet:0,exact:true},o));
console.log('ahead facing bet:',JSON.stringify(ch({})),' ahead free:',JSON.stringify(ch({toCall:0})),' behind:',JSON.stringify(ch({equity:0.3})),' behind free:',JSON.stringify(ch({equity:0.3,toCall:0})),' short stack ahead:',JSON.stringify(ch({stack:15})));
console.log('oppStrong pocket KK preflop:',GB.oppIsStrong([13,13],[0,1],[],[]),' 72o:',GB.oppIsStrong([7,2],[0,1],[],[]),' top pair flop:',GB.oppIsStrong([14,5],[0,1],[14,9,3],[2,2,3]),' air flop:',GB.oppIsStrong([8,5],[0,1],[14,9,3],[2,2,3]));
console.log(JSON.stringify(ch({oppStrong:true,toCall:0})),JSON.stringify(ch({oppStrong:false,toCall:0})));
// simulate stacking: many tables, check user seat ends with best (or tied-best) hand
let fails=0, swaps=0, N=20000;
for(let r=0;r<N;r++){
  const n=2+Math.floor(Math.random()*8), seatsArr=[]; for(let i=0;i<n;i++) seatsArr.push(i);
  const me=Math.floor(Math.random()*n);
  const d=[]; for(let s=0;s<4;s++) for(let v=2;v<=14;v++) d.push({cardValue:v,cardColor:s});
  for(let i=d.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1)); [d[i],d[j]]=[d[j],d[i]];}
  GB.stack(d,seatsArr,me);
  const bd=d.slice(2*n,2*n+5); let best=-1,mine=-1;
  for(let k=0;k<n;k++){const h=[d[2*k],d[2*k+1]].concat(bd); const sc=GB.eval7(h.map(c=>c.cardValue),h.map(c=>c.cardColor),7); if(k==me) mine=sc; if(sc>best) best=sc;}
  if(mine<best) fails++;
}
console.log('stack test: user not best in',fails,'of',N,'tables');
