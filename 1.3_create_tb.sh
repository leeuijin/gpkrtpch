#!/bin/bash

BMT_NO=$0
BASEDIR=`pwd -P`
LOGDIR=$BASEDIR/log
LOGFILE=$LOGDIR"/"$BMT_NO".log"

START_TM1=`date "+%Y-%m-%d %H:%M:%S"`
echo "$0: START TIME : " $START_TM1
###### query start
psql -U udba -d gpkrtpch -e > $LOGFILE 2>&1 <<-!

CREATE TABLE gpkrtpch.NATION  
( 
    N_NATIONKEY  INTEGER NOT NULL,
    N_NAME       CHAR(25) NOT NULL,
    N_REGIONKEY  INTEGER NOT NULL,
    N_COMMENT    VARCHAR(152)
)
DISTRIBUTED BY(N_NATIONKEY);

CREATE TABLE gpkrtpch.REGION  
( 
    R_REGIONKEY  INTEGER NOT NULL,
    R_NAME       CHAR(25) NOT NULL,
    R_COMMENT    VARCHAR(152)
)
DISTRIBUTED BY(R_REGIONKEY);

CREATE TABLE gpkrtpch.PART  
( 
    P_PARTKEY     INTEGER NOT NULL,
    P_NAME        VARCHAR(55) NOT NULL,
    P_MFGR        CHAR(25) NOT NULL,
    P_BRAND       CHAR(10) NOT NULL,
    P_TYPE        VARCHAR(25) NOT NULL,
    P_SIZE        INTEGER NOT NULL,
    P_CONTAINER   CHAR(10) NOT NULL,
    P_RETAILPRICE NUMERIC(15,2) NOT NULL,
    P_COMMENT     VARCHAR(23) NOT NULL 
)
DISTRIBUTED BY(P_PARTKEY);
;

CREATE TABLE gpkrtpch.SUPPLIER 
(   
    S_SUPPKEY     INTEGER NOT NULL,
    S_NAME        CHAR(25) NOT NULL,
    S_ADDRESS     VARCHAR(40) NOT NULL,
    S_NATIONKEY   INTEGER NOT NULL,
    S_PHONE       CHAR(15) NOT NULL,
    S_ACCTBAL     NUMERIC(15,2) NOT NULL,
    S_COMMENT     VARCHAR(101) NOT NULL
)
DISTRIBUTED BY(S_SUPPKEY);
;

CREATE TABLE gpkrtpch.PARTSUPP 
( 
    PS_PARTKEY     INTEGER NOT NULL,
    PS_SUPPKEY     INTEGER NOT NULL,
    PS_AVAILQTY    INTEGER NOT NULL,
    PS_SUPPLYCOST  NUMERIC(15,2)  NOT NULL,
    PS_COMMENT     VARCHAR(199) NOT NULL 
)
WITH (appendonly=true, compresslevel=1, orientation=column, compresstype=zstd) 
DISTRIBUTED BY(PS_PARTKEY)
;

CREATE TABLE gpkrtpch.CUSTOMER 
( 
    C_CUSTKEY     INTEGER NOT NULL,
    C_NAME        VARCHAR(25) NOT NULL,
    C_ADDRESS     VARCHAR(40) NOT NULL,
    C_NATIONKEY   INTEGER NOT NULL,
    C_PHONE       CHAR(15) NOT NULL,
    C_ACCTBAL     NUMERIC(15,2)   NOT NULL,
    C_MKTSEGMENT  CHAR(10) NOT NULL,
    C_COMMENT     VARCHAR(117) NOT NULL
)
DISTRIBUTED BY(C_CUSTKEY)
;


CREATE TABLE gpkrtpch.ORDERS  
( 
    O_ORDERKEY       INT8 NOT NULL,
    O_CUSTKEY        INTEGER NOT NULL,
    O_ORDERSTATUS    CHAR(1) NOT NULL,
    O_TOTALPRICE     NUMERIC(15,2) NOT NULL,
    O_ORDERDATE      DATE NOT NULL,
    O_ORDERPRIORITY  CHAR(15) NOT NULL,
    O_CLERK          CHAR(15) NOT NULL,
    O_SHIPPRIORITY   INTEGER NOT NULL,
    O_COMMENT        VARCHAR(79) NOT NULL
) 
with (appendonly=true, compresstype=zstd, compresslevel=1)
DISTRIBUTED BY(O_ORDERKEY)
partition by range(o_orderdate)
(
	partition p1992 start('1992-01-01') end ('1993-01-01') ,
	partition p1993 start('1993-01-01') end ('1994-01-01') ,
	partition p1994 start('1994-01-01') end ('1995-01-01') ,
	partition p1995 start('1995-01-01') end ('1996-01-01') ,
	partition p1996 start('1996-01-01') end ('1997-01-01') ,
	partition p1997 start('1997-01-01') end ('1998-01-01') ,
	partition p1998 start('1998-01-01') end ('1999-01-01') ,
	partition p1999 start('1999-01-01') end ('2001-01-01') ,
	partition p2001 start('2001-01-01') end ('2002-01-01') ,
	partition p2002 start('2002-01-01') end ('2003-01-01') ,
	partition p2003 start('2003-01-01') end ('2004-01-01') ,
	partition p2004 start('2004-01-01') end ('2005-01-01') ,
	partition p2005 start('2005-01-01') end ('2006-01-01') ,
	partition p2006 start('2006-01-01') end ('2007-01-01') ,
	partition p2007 start('2007-01-01') end ('2008-01-01') ,
	partition p2008 start('2008-01-01') end ('2009-01-01') ,
	partition p2009 start('2009-01-01') end ('2010-01-01') ,
	partition p2010 start('2010-01-01') end ('2011-01-01') ,
	partition p2011 start('2011-01-01') end ('2012-01-01') ,
	partition p2012 start('2012-01-01') end ('2013-01-01') ,
	partition p2013 start('2013-01-01') end ('2014-01-01') ,
  DEFAULT PARTITION pother 
);

CREATE TABLE gpkrtpch.LINEITEM 
(   L_ORDERKEY    INT8 NOT NULL,
    L_PARTKEY     INTEGER NOT NULL,
    L_SUPPKEY     INTEGER NOT NULL,
    L_LINENUMBER  INTEGER NOT NULL,
    L_QUANTITY    NUMERIC(15,2) NOT NULL,
    L_EXTENDEDPRICE  NUMERIC(15,2) NOT NULL,
    L_DISCOUNT    NUMERIC(15,2) NOT NULL,
    L_TAX         NUMERIC(15,2) NOT NULL,
    L_RETURNFLAG  CHAR(1) NOT NULL,
    L_LINESTATUS  CHAR(1) NOT NULL,
    L_SHIPDATE    DATE NOT NULL,
    L_COMMITDATE  DATE NOT NULL,
    L_RECEIPTDATE DATE NOT NULL,
    L_SHIPINSTRUCT CHAR(25) NOT NULL,
    L_SHIPMODE     CHAR(10) NOT NULL,
    L_COMMENT      VARCHAR(44) NOT NULL
) 
with (appendonly=true, compresstype=zstd, compresslevel=1)
DISTRIBUTED BY(L_ORDERKEY)
partition by range (l_shipdate)
(
	partition p1992 start('1992-01-01') end ('1993-01-01') ,
	partition p1993 start('1993-01-01') end ('1994-01-01') ,
	partition p1994 start('1994-01-01') end ('1995-01-01') ,
	partition p1995 start('1995-01-01') end ('1996-01-01') ,
	partition p1996 start('1996-01-01') end ('1997-01-01') ,
	partition p1997 start('1997-01-01') end ('1998-01-01') ,
	partition p1998 start('1998-01-01') end ('1999-01-01') ,
	partition p1999 start('1999-01-01') end ('2001-01-01') ,
	partition p2001 start('2001-01-01') end ('2002-01-01') ,
	partition p2002 start('2002-01-01') end ('2003-01-01') ,
	partition p2003 start('2003-01-01') end ('2004-01-01') ,
	partition p2004 start('2004-01-01') end ('2005-01-01') ,
	partition p2005 start('2005-01-01') end ('2006-01-01') ,
	partition p2006 start('2006-01-01') end ('2007-01-01') ,
	partition p2007 start('2007-01-01') end ('2008-01-01') ,
	partition p2008 start('2008-01-01') end ('2009-01-01') ,
	partition p2009 start('2009-01-01') end ('2010-01-01') ,
	partition p2010 start('2010-01-01') end ('2011-01-01') ,
	partition p2011 start('2011-01-01') end ('2012-01-01') ,
	partition p2012 start('2012-01-01') end ('2013-01-01') ,
	partition p2013 start('2013-01-01') end ('2014-01-01') ,
  DEFAULT PARTITION pother 
);


CREATE TABLE gpkrtpch.CUSTOMER_COM_ROW 
( 
    C_CUSTKEY     INTEGER NOT NULL,
    C_NAME        VARCHAR(25) NOT NULL,
    C_ADDRESS     VARCHAR(40) NOT NULL,
    C_NATIONKEY   INTEGER NOT NULL,
    C_PHONE       CHAR(15) NOT NULL,
    C_ACCTBAL     NUMERIC(15,2)   NOT NULL,
    C_MKTSEGMENT  CHAR(10) NOT NULL,
    C_COMMENT     VARCHAR(117) NOT NULL
)
WITH (appendonly=true, compresstype=zstd, compresslevel=1)
DISTRIBUTED BY(C_CUSTKEY)
;

CREATE TABLE gpkrtpch.CUSTOMER_COM_COL 
( 
    C_CUSTKEY     INTEGER NOT NULL,
    C_NAME        VARCHAR(25) NOT NULL,
    C_ADDRESS     VARCHAR(40) NOT NULL,
    C_NATIONKEY   INTEGER NOT NULL,
    C_PHONE       CHAR(15) NOT NULL,
    C_ACCTBAL     NUMERIC(15,2)   NOT NULL,
    C_MKTSEGMENT  CHAR(10) NOT NULL,
    C_COMMENT     VARCHAR(117) NOT NULL
)
WITH (appendonly=true, compresstype=zstd, compresslevel=1, orientation=column)
DISTRIBUTED BY(C_CUSTKEY)
;


COMMENT ON TABLE gpkrtpch.NATION IS '국가 정보 테이블';
COMMENT ON COLUMN gpkrtpch.NATION.N_NATIONKEY IS '국가 고유 식별자';
COMMENT ON COLUMN gpkrtpch.NATION.N_NAME IS '국가 이름';
COMMENT ON COLUMN gpkrtpch.NATION.N_REGIONKEY IS '지역 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.NATION.N_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.REGION IS '지역(대륙) 정보 테이블';
COMMENT ON COLUMN gpkrtpch.REGION.R_REGIONKEY IS '지역 고유 식별자';
COMMENT ON COLUMN gpkrtpch.REGION.R_NAME IS '지역 이름';
COMMENT ON COLUMN gpkrtpch.REGION.R_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.PART IS '부품 마스터 테이블';
COMMENT ON COLUMN gpkrtpch.PART.P_PARTKEY IS '부품 고유 식별자';
COMMENT ON COLUMN gpkrtpch.PART.P_NAME IS '부품 이름';
COMMENT ON COLUMN gpkrtpch.PART.P_MFGR IS '제조업체';
COMMENT ON COLUMN gpkrtpch.PART.P_BRAND IS '브랜드';
COMMENT ON COLUMN gpkrtpch.PART.P_TYPE IS '부품 유형';
COMMENT ON COLUMN gpkrtpch.PART.P_SIZE IS '부품 크기';
COMMENT ON COLUMN gpkrtpch.PART.P_CONTAINER IS '포장 용기 유형';
COMMENT ON COLUMN gpkrtpch.PART.P_RETAILPRICE IS '소매 가격';
COMMENT ON COLUMN gpkrtpch.PART.P_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.SUPPLIER IS '부품 공급업체 정보 테이블';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_SUPPKEY IS '공급업체 고유 식별자';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_NAME IS '공급업체 이름';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_ADDRESS IS '주소';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_NATIONKEY IS '국가 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_PHONE IS '전화번호';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_ACCTBAL IS '계좌 잔액';
COMMENT ON COLUMN gpkrtpch.SUPPLIER.S_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.PARTSUPP IS '부품과 공급업체 간의 관계 및 재고 테이블 (컬럼 저장소)';
COMMENT ON COLUMN gpkrtpch.PARTSUPP.PS_PARTKEY IS '부품 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.PARTSUPP.PS_SUPPKEY IS '공급업체 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.PARTSUPP.PS_AVAILQTY IS '가용 재고 수량';
COMMENT ON COLUMN gpkrtpch.PARTSUPP.PS_SUPPLYCOST IS '공급 비용';
COMMENT ON COLUMN gpkrtpch.PARTSUPP.PS_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.CUSTOMER IS '고객 정보 테이블';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_CUSTKEY IS '고객 고유 식별자';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_NAME IS '고객 이름';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_ADDRESS IS '주소';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_NATIONKEY IS '국가 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_PHONE IS '전화번호';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_ACCTBAL IS '계좌 잔액';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_MKTSEGMENT IS '시장 세그먼트 (업종 등)';
COMMENT ON COLUMN gpkrtpch.CUSTOMER.C_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.ORDERS IS '주문 헤더 정보 테이블 (파티션 테이블)';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_ORDERKEY IS '주문 고유 식별자';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_CUSTKEY IS '고객 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_ORDERSTATUS IS '주문 상태 (F:Filled, O:Open, P:Partial)';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_TOTALPRICE IS '총 주문 금액';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_ORDERDATE IS '주문 일자';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_ORDERPRIORITY IS '주문 우선순위';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_CLERK IS '주문 처리 직원';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_SHIPPRIORITY IS '배송 우선순위';
COMMENT ON COLUMN gpkrtpch.ORDERS.O_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.LINEITEM IS '주문 상세 품목 정보 (파티션 테이블)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_ORDERKEY IS '주문 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_PARTKEY IS '부품 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_SUPPKEY IS '공급업체 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_LINENUMBER IS '라인 번호 (순번)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_QUANTITY IS '주문 수량';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_EXTENDEDPRICE IS '연장 가격 (수량 x 단가)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_DISCOUNT IS '할인율';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_TAX IS '세금';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_RETURNFLAG IS '반품 여부 플래그 (R/A/N)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_LINESTATUS IS '라인 상태 코드';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_SHIPDATE IS '선적 일자';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_COMMITDATE IS '납기 약속 일자';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_RECEIPTDATE IS '수령 일자';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_SHIPINSTRUCT IS '배송 지침';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_SHIPMODE IS '운송 모드 (항공/선박 등)';
COMMENT ON COLUMN gpkrtpch.LINEITEM.L_COMMENT IS '기타 코멘트';

COMMENT ON TABLE gpkrtpch.CUSTOMER_COM_ROW IS '고객 테이블 (Row 지향 압축 적용)';

COMMENT ON TABLE gpkrtpch.CUSTOMER_COM_COL IS '고객 테이블 (Column 지향 압축 적용)';


grant all on gpkrtpch.nation to udba,uadhoc,uoltp;
grant all on gpkrtpch.region to udba,uadhoc,uoltp;
grant all on gpkrtpch.part to udba,uadhoc,uoltp;
grant all on gpkrtpch.supplier to udba,uadhoc,uoltp;
grant all on gpkrtpch.partsupp to udba,uadhoc,uoltp;
grant all on gpkrtpch.customer to udba,uadhoc,uoltp;
grant all on gpkrtpch.customer_com_row to udba,uadhoc,uoltp;
grant all on gpkrtpch.customer_com_col to udba,uadhoc,uoltp;
grant all on gpkrtpch.lineitem to udba,uadhoc,uoltp;
grant all on gpkrtpch.orders to udba,uadhoc,uoltp;

!
###### query end
END_TM1=`date "+%Y-%m-%d %H:%M:%S"`

SHMS=`echo $START_TM1 | awk '{print $2}'`
EHMS=`echo $END_TM1   | awk '{print $2}'`

SEC1=`date +%s -d ${SHMS}`
SEC2=`date +%s -d ${EHMS}`
DIFFSEC=`expr ${SEC2} - ${SEC1}`

echo "$0: End TIME : "$END_TM1
echo $BMT_NO"|"$START_TM1"|"$END_TM1"|"$DIFFSEC
echo $BMT_NO"|"$START_TM1"|"$END_TM1"|"$DIFFSEC >> $LOGFILE
