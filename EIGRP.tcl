# ======================================================================
# Simulation: EIGRP Behavior using Metric Manipulation
# ======================================================================

set ns [new Simulator]


$ns color 1 Blue
$ns color 2 Red


set namfile [open out.nam w]
$ns namtrace-all $namfile
set tracefile [open out.tr w]
$ns trace-all $tracefile


set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]

# ======================================================================
# الطوبولوجيا:
# سنخلق مسارين من n0 إلى n4
# المسار العلوي (n0-n1-n2-n4): طويل (3 قفزات) لكنه سريع (2Mb)
# المسار السفلي (n0-n3-n4): قصير (قفزتين) لكنه بطيء جداً (0.5Mb) - يمثل الازدحام
# ======================================================================

# الروابط العلوية (السريعة)
$ns duplex-link $n0 $n1 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n4 2Mb 10ms DropTail

# الروابط السفلية (البطيئة/المزدحمة)
$ns duplex-link $n0 $n3 0.5Mb 10ms DropTail
$ns duplex-link $n3 $n4 0.5Mb 10ms DropTail


$ns duplex-link-op $n0 $n1 orient right-up
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $n4 orient right-down
$ns duplex-link-op $n0 $n3 orient right-down
$ns duplex-link-op $n3 $n4 orient right-up



$ns rtproto DV

# تكلفة الروابط السريعة (نجعلها منخفضة جداً)
$ns cost $n0 $n1 1
$ns cost $n1 $n2 1
$ns cost $n2 $n4 1
$ns cost $n1 $n0 1
$ns cost $n2 $n1 1
$ns cost $n4 $n2 1
# المجموع للمسار العلوي = 1+1+1 = 3

# تكلفة الروابط البطيئة (نجعلها مرتفعة لمحاكاة معادلة EIGRP)
$ns cost $n0 $n3 10
$ns cost $n3 $n4 10
$ns cost $n3 $n0 10
$ns cost $n4 $n3 10
# المجموع للمسار السفلي = 10+10 = 20


set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0
set null0 [new Agent/Null]
$ns attach-agent $n4 $null0
$ns connect $udp0 $null0
$udp0 set fid_ 1

set cbr0 [new Application/Traffic/CBR]
$cbr0 attach-agent $udp0
$cbr0 set packetSize_ 1000
$cbr0 set rate_ 1.5Mb 
$cbr0 set random_ false

$ns at 0.5 "$cbr0 start"
$ns at 4.5 "$cbr0 stop"
$ns at 5.0 "finish"

proc finish {} {
    global ns namfile tracefile
    $ns flush-trace
    close $namfile
    close $tracefile
    exec nam out.nam &
    exit 0
}

$ns run
