#!/usr/bin/per;

# proxy settings
#$ENV{http_proxy} = 'http://your-proxy:8080';
#$ENV{https_proxy} = 'http://your-proxy:8080';

#credentials
my $url = "https://gateway.watsonplatform.net/natural-language-classifier/api";
my $username = "your-username"; # ← NLC の credential から username をコピペ
my $password = "your-password"; # ← NLC の credential から password をコピペ

# 開始時刻を保存
my $start = time;

# 分類器情報取得
my @classifiers;
my $re = `curl -s -u $username:$password $url/v1/classifiers`;
my @line = split(/\r|\n/,$re);
for(@line){
    if(/"classifier_id" : "(.+)"/){
        my $id = $1;
        push @classifiers, $id;
        print "$id\n";
    }
}

my %status;
my $count = 3600; # 最大10時間
while($count--){
    my$found = 0;
    for $id (@classifiers){
        if(!$status{$id} || $status{$id} eq "Training"){
            $found = 1;
            my $re = `curl -s -u $username:$password $url/v1/classifiers/$id`;
            my @line = split(/\r|\n/,$re);
            my $status;

            for(@line){
                if(/"status" : "(.+)"/){
                    $status = $1;
                    print scalar(localtime), " $id $status\n";
                    $status{$id} = $status;
                }
            }
        }
    }
    # 1つもTrainingの分類器がなければ終了
    if(!$found){
        print scalar(localtime), " Finished\n";
        my $end = time;
        my $sec = $end - $start;
        my $min = int($sec / 60);
        print scalar(localtime), " Elapsed $min minutes ($sec seconds)\n";
        exit;
    }
    sleep(10);
}

# 10時間たって終了したらこっち
print scalar(localtime), " Timed out\n";
my $end = time;
my $sec = $end - $start;
my $min = int($sec / 60);
print scalar(localtime), " Elapsed $min minutes ($sec seconds)\n";