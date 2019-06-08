from ofxtools.Parser import OFXTree

parser = OFXTree()

with open('../otm-stephen/bank-files/anz-stephen-music-2017-07-2018-12.ofx', 'rb') as f:  # N.B. need to open file in binary mode
    parser.parse(f)

ofx = parser.convert()

stmts = ofx.statements 
txs = stmts[0].transactions 


for tx in txs:
    print (tx.trnamt)
    print (tx.trntype)
    print (tx.dtposted)
    print (tx.fitid)
    print (tx.name)
    print (tx.memo)
    



