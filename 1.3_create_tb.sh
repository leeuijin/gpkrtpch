#!/bin/bash

BMT_NO=$0
BASEDIR=`pwd -P`
LOGDIR=$BASEDIR/log
LOGFILE=$LOGDIR"/"$BMT_NO".log"

START_TM1=`date "+%Y-%m-%d %H:%M:%S"`
echo "$0: START TIME : " $START_TM1
###### query start
psql -U udba -d gpkrtpch -e > $LOGFILE 2>&1 <<-!

-- ============================================
-- NATION : 국가 정보 테이블
-- ============================================
CREATE TABLE gpkrtpch.NATION  
( 
    N_NATIONKEY  INTEGER NOT NULL,     -- 국가 PK
    N_NAME       CHAR(25) NOT NULL,    -- 국가명
    N_REGIONKEY  INTEGER NOT NULL,     -- 소속 지역 FK
    N_COMMENT    VARCHAR(152)          -- 비고
)
DISTRIBUTED BY(N_NATIONKEY);           -- 국가키 기준 분산


-- ============================================
-- REGION : 지역 정보 테이블
-- ============================================
CREATE TABLE gpkrtpch.REGION  
( 
    R_REGIONKEY  INTEGER NOT NULL,     -- 지역 PK
    R_NAME       CHAR(25) NOT NULL,    -- 지역명
    R_COMMENT    VARCHAR(152)          -- 비고
)
DISTRIBUTED BY(R_REGIONKEY);           -- 지역키 기준 분산


-- ============================================
-- PART : 상품 마스터 테이블
-- ============================================
CREATE TABLE gpkrtpch.PART  
( 
    P_PARTKEY     INTEGER NOT NULL,        -- 상품 PK
    P_NAME        VARCHAR(55) NOT NULL,    -- 상품명
    P_MFGR        CHAR(25) NOT NULL,       -- 제조사
    P_BRAND       CHAR(10) NOT NULL,       -- 브랜드
    P_TYPE        VARCHAR(25) NOT NULL,    -- 상품 유형
    P_SIZE        INTEGER NOT NULL,        -- 상품 사이즈
    P_CONTAINER   CHAR(10) NOT NULL,       -- 포장 유형
    P_RETAILPRICE NUMERIC(15,2) NOT NULL,  -- 소비자가격
    P_COMMENT     VARCHAR(23) NOT NULL     -- 비고
)
DISTRIBUTED BY(P_PARTKEY);                 -- 상품키 기준 분산


-- ============================================
-- SUPPLIER : 공급업체 테이블
-- ============================================
CREATE TABLE gpkrtpch.SUPPLIER 
(   
    S_SUPPKEY     INTEGER NOT NULL,        -- 공급업체 PK
    S_NAME        CHAR(25) NOT NULL,       -- 업체명
    S_ADDRESS     VARCHAR(40) NOT NULL,    -- 주소
    S_NATIONKEY   INTEGER NOT NULL,        -- 국가 FK
    S_PHONE       CHAR(15) NOT NULL,       -- 전화번호
    S_ACCTBAL     NUMERIC(15,2) NOT NULL,  -- 계좌 잔액
    S_COMMENT     VARCHAR(101) NOT NULL    -- 비고
)
DISTRIBUTED BY(S_SUPPKEY);                 -- 공급업체키 기준 분산


-- ============================================
-- PARTSUPP : 상품-공급업체 매핑 테이블
-- AO + 컬럼스토어 (압축 zstd)
-- ============================================
CREATE TABLE gpkrtpch.PARTSUPP 
( 
    PS_PARTKEY     INTEGER NOT NULL,        -- 상품 FK
    PS_SUPPKEY     INTEGER NOT NULL,        -- 공급업체 FK
    PS_AVAILQTY    INTEGER NOT NULL,        -- 가용 수량
    PS_SUPPLYCOST  NUMERIC(15,2) NOT NULL,  -- 공급 단가
    PS_COMMENT     VARCHAR(199) NOT NULL    -- 비고
)
WITH (
    appendonly=true,         -- AO 테이블 (UPDATE 적고 대량 조회용)
    compresslevel=1,         -- 압축 레벨
    orientation=column,      -- 컬럼 지향 저장
    compresstype=zstd        -- zstd 압축
) 
DISTRIBUTED BY(PS_PARTKEY);  -- 상품키 기준 분산


-- ============================================
-- CUSTOMER : 고객 테이블 (Heap 구조)
-- ============================================
CREATE TABLE gpkrtpch.CUSTOMER 
( 
    C_CUSTKEY     INTEGER NOT NULL,        -- 고객 PK
    C_NAME        VARCHAR(25) NOT NULL,    -- 고객명
    C_ADDRESS     VARCHAR(40) NOT NULL,    -- 주소
    C_NATIONKEY   INTEGER NOT NULL,        -- 국가 FK
    C_PHONE       CHAR(15) NOT NULL,       -- 전화번호
    C_ACCTBAL     NUMERIC(15,2) NOT NULL,  -- 계좌 잔액
    C_MKTSEGMENT  CHAR(10) NOT NULL,       -- 마케팅 세그먼트
    C_COMMENT     VARCHAR(117) NOT NULL    -- 비고
)
DISTRIBUTED BY(C_CUSTKEY);                 -- 고객키 기준 분산


-- ============================================
-- ORDERS : 주문 테이블
-- AO + Range Partition (주문일자 기준)
-- ============================================
CREATE TABLE gpkrtpch.ORDERS  
( 
    O_ORDERKEY       INT8 NOT NULL,        -- 주문 PK
    O_CUSTKEY        INTEGER NOT NULL,     -- 고객 FK
    O_ORDERSTATUS    CHAR(1) NOT NULL,     -- 주문 상태
    O_TOTALPRICE     NUMERIC(15,2) NOT NULL,-- 총 금액
    O_ORDERDATE      DATE NOT NULL,        -- 주문일
    O_ORDERPRIORITY  CHAR(15) NOT NULL,    -- 우선순위
    O_CLERK          CHAR(15) NOT NULL,    -- 담당자
    O_SHIPPRIORITY   INTEGER NOT NULL,     -- 배송 우선순위
    O_COMMENT        VARCHAR(79) NOT NULL  -- 비고
) 
WITH (
    appendonly=true,       -- AO 테이블
    compresstype=zstd,     -- 압축 타입
    compresslevel=1
)
DISTRIBUTED BY(O_ORDERKEY) -- 주문키 기준 분산
PARTITION BY RANGE(o_orderdate)  -- 주문일 기준 Range 파티션
(
    -- 연도별 파티션 구성 (파티션 프루닝 목적)
    PARTITION p1992 START('1992-01-01') END ('1993-01-01'),
    PARTITION p1993 START('1993-01-01') END ('1994-01-01'),
    ...
    PARTITION p2013 START('2013-01-01') END ('2014-01-01'),
    DEFAULT PARTITION pother  -- 범위 외 데이터 저장
);


-- ============================================
-- LINEITEM : 주문 상세 테이블
-- AO + Range Partition (출고일 기준)
-- ============================================
CREATE TABLE gpkrtpch.LINEITEM 
(   
    L_ORDERKEY    INT8 NOT NULL,           -- 주문 FK
    L_PARTKEY     INTEGER NOT NULL,        -- 상품 FK
    L_SUPPKEY     INTEGER NOT NULL,        -- 공급업체 FK
    L_LINENUMBER  INTEGER NOT NULL,        -- 라인 번호
    L_QUANTITY    NUMERIC(15,2) NOT NULL,  -- 수량
    L_EXTENDEDPRICE NUMERIC(15,2) NOT NULL,-- 확장 금액
    L_DISCOUNT    NUMERIC(15,2) NOT NULL,  -- 할인율
    L_TAX         NUMERIC(15,2) NOT NULL,  -- 세금
    L_RETURNFLAG  CHAR(1) NOT NULL,        -- 반품 여부
    L_LINESTATUS  CHAR(1) NOT NULL,        -- 라인 상태
    L_SHIPDATE    DATE NOT NULL,           -- 배송일
    L_COMMITDATE  DATE NOT NULL,           -- 확정일
    L_RECEIPTDATE DATE NOT NULL,           -- 수령일
    L_SHIPINSTRUCT CHAR(25) NOT NULL,      -- 배송 지시사항
    L_SHIPMODE     CHAR(10) NOT NULL,      -- 배송 방식
    L_COMMENT      VARCHAR(44) NOT NULL    -- 비고
) 
WITH (
    appendonly=true,
    compresstype=zstd,
    compresslevel=1
)
DISTRIBUTED BY(L_ORDERKEY)   -- 주문키 기준 분산 (ORDERS와 조인 최적화)
PARTITION BY RANGE (l_shipdate)  -- 출고일 기준 파티션
(
    PARTITION p1992 START('1992-01-01') END ('1993-01-01'),
    ...
    PARTITION p2013 START('2013-01-01') END ('2014-01-01'),
    DEFAULT PARTITION pother
);


-- ============================================
-- CUSTOMER_COM_ROW : AO Row Store 테스트용
-- ============================================
CREATE TABLE gpkrtpch.CUSTOMER_COM_ROW 
(
    -- CUSTOMER 동일 구조
)
WITH (
    appendonly=true,
    compresstype=zstd,
    compresslevel=1
)
DISTRIBUTED BY(C_CUSTKEY);


-- ============================================
-- CUSTOMER_COM_COL : AO Column Store 테스트용
-- ============================================
CREATE TABLE gpkrtpch.CUSTOMER_COM_COL 
(
    -- CUSTOMER 동일 구조
)
WITH (
    appendonly=true,
    compresstype=zstd,
    compresslevel=1,
    orientation=column   -- 컬럼 지향 저장
)
DISTRIBUTED BY(C_CUSTKEY);


-- ============================================
-- 권한 부여
-- ============================================
-- udba, uadhoc, uoltp 사용자에게 전체 권한 부여
GRANT ALL ON gpkrtpch.nation TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.region TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.part TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.supplier TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.partsupp TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.customer TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.customer_com_row TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.customer_com_col TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.lineitem TO udba,uadhoc,uoltp;
GRANT ALL ON gpkrtpch.orders TO udba,uadhoc,uoltp;

-- ============================================
-- 코맨트
-- ============================================

COMMENT ON TABLE gpkrtpch.customer IS '고객 정보 테이블';
COMMENT ON COLUMN gpkrtpch.customer.c_custkey IS '고객 고유 식별자';
COMMENT ON COLUMN gpkrtpch.customer.c_name IS '고객 이름';
COMMENT ON COLUMN gpkrtpch.customer.c_address IS '주소';
COMMENT ON COLUMN gpkrtpch.customer.c_nationkey IS '국가 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.customer.c_phone IS '전화번호';
COMMENT ON COLUMN gpkrtpch.customer.c_acctbal IS '계좌 잔액';
COMMENT ON COLUMN gpkrtpch.customer.c_mktsegment IS '시장 세그먼트 (업종 등)';
COMMENT ON COLUMN gpkrtpch.customer.c_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.customer_com_col IS '고객 테이블 (Column 지향 압축 적용)';
COMMENT ON TABLE gpkrtpch.customer_com_row IS '고객 테이블 (Row 지향 압축 적용)';
COMMENT ON TABLE gpkrtpch.lineitem IS '주문 상세 품목 정보 (파티션 테이블)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_orderkey IS '주문 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_partkey IS '부품 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_suppkey IS '공급업체 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_linenumber IS '라인 번호 (순번)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_quantity IS '주문 수량';
COMMENT ON COLUMN gpkrtpch.lineitem.l_extendedprice IS '연장 가격 (수량 x 단가)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_discount IS '할인율';
COMMENT ON COLUMN gpkrtpch.lineitem.l_tax IS '세금';
COMMENT ON COLUMN gpkrtpch.lineitem.l_returnflag IS '반품 여부 플래그 (R/A/N)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_linestatus IS '라인 상태 코드';
COMMENT ON COLUMN gpkrtpch.lineitem.l_shipdate IS '선적 일자';
COMMENT ON COLUMN gpkrtpch.lineitem.l_commitdate IS '납기 약속 일자';
COMMENT ON COLUMN gpkrtpch.lineitem.l_receiptdate IS '수령 일자';
COMMENT ON COLUMN gpkrtpch.lineitem.l_shipinstruct IS '배송 지침';
COMMENT ON COLUMN gpkrtpch.lineitem.l_shipmode IS '운송 모드 (항공/선박 등)';
COMMENT ON COLUMN gpkrtpch.lineitem.l_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.nation IS '국가 정보 테이블';
COMMENT ON COLUMN gpkrtpch.nation.n_nationkey IS '국가 고유 식별자';
COMMENT ON COLUMN gpkrtpch.nation.n_name IS '국가 이름';
COMMENT ON COLUMN gpkrtpch.nation.n_regionkey IS '지역 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.nation.n_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.orders IS '주문 헤더 정보 테이블 (파티션 테이블)';
COMMENT ON COLUMN gpkrtpch.orders.o_orderkey IS '주문 고유 식별자';
COMMENT ON COLUMN gpkrtpch.orders.o_custkey IS '고객 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.orders.o_orderstatus IS '주문 상태 (F:Filled, O:Open, P:Partial)';
COMMENT ON COLUMN gpkrtpch.orders.o_totalprice IS '총 주문 금액';
COMMENT ON COLUMN gpkrtpch.orders.o_orderdate IS '주문 일자';
COMMENT ON COLUMN gpkrtpch.orders.o_orderpriority IS '주문 우선순위';
COMMENT ON COLUMN gpkrtpch.orders.o_clerk IS '주문 처리 직원';
COMMENT ON COLUMN gpkrtpch.orders.o_shippriority IS '배송 우선순위';
COMMENT ON COLUMN gpkrtpch.orders.o_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.part IS '부품 마스터 테이블';
COMMENT ON COLUMN gpkrtpch.part.p_partkey IS '부품 고유 식별자';
COMMENT ON COLUMN gpkrtpch.part.p_name IS '부품 이름';
COMMENT ON COLUMN gpkrtpch.part.p_mfgr IS '제조업체';
COMMENT ON COLUMN gpkrtpch.part.p_brand IS '브랜드';
COMMENT ON COLUMN gpkrtpch.part.p_type IS '부품 유형';
COMMENT ON COLUMN gpkrtpch.part.p_size IS '부품 크기';
COMMENT ON COLUMN gpkrtpch.part.p_container IS '포장 용기 유형';
COMMENT ON COLUMN gpkrtpch.part.p_retailprice IS '소매 가격';
COMMENT ON COLUMN gpkrtpch.part.p_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.partsupp IS '부품과 공급업체 간의 관계 및 재고 테이블 (컬럼 저장소)';
COMMENT ON COLUMN gpkrtpch.partsupp.ps_partkey IS '부품 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.partsupp.ps_suppkey IS '공급업체 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.partsupp.ps_availqty IS '가용 재고 수량';
COMMENT ON COLUMN gpkrtpch.partsupp.ps_supplycost IS '공급 비용';
COMMENT ON COLUMN gpkrtpch.partsupp.ps_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.region IS '지역(대륙) 정보 테이블';
COMMENT ON COLUMN gpkrtpch.region.r_regionkey IS '지역 고유 식별자';
COMMENT ON COLUMN gpkrtpch.region.r_name IS '지역 이름';
COMMENT ON COLUMN gpkrtpch.region.r_comment IS '기타 코멘트';
COMMENT ON TABLE gpkrtpch.supplier IS '부품 공급업체 정보 테이블';
COMMENT ON COLUMN gpkrtpch.supplier.s_suppkey IS '공급업체 고유 식별자';
COMMENT ON COLUMN gpkrtpch.supplier.s_name IS '공급업체 이름';
COMMENT ON COLUMN gpkrtpch.supplier.s_address IS '주소';
COMMENT ON COLUMN gpkrtpch.supplier.s_nationkey IS '국가 식별자 (FK)';
COMMENT ON COLUMN gpkrtpch.supplier.s_phone IS '전화번호';
COMMENT ON COLUMN gpkrtpch.supplier.s_acctbal IS '계좌 잔액';
COMMENT ON COLUMN gpkrtpch.supplier.s_comment IS '기타 코멘트';

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

