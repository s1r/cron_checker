#!/usr/bin/perl

use strict;
use warnings;
use Time::Local;
use POSIX qw(strftime); # Time::Piece の代わりに POSIX::strftime を使用
use utf8;

binmode(STDOUT, ":utf8");

# crontab の内容を取得
my @crontab = `crontab -l 2>/dev/null`;

# 現在の日時を取得
my $now = time;

# 一週間前の日時を計算
my $one_week_before = $now - 60 * 60 * 24 * 7;

# 一週間後の日時を計算
my $one_week_later = $now + 60 * 60 * 24 * 7;

# 毎分ループでチェック
for (my $current_time = $one_week_before; $current_time <= $one_week_later; $current_time += 60) {

    # 現在時刻を表示
    if ($current_time == $now) {
        my $formatted_time = strftime "%Y-%m-%d %a %H:%M", localtime $current_time;
        print "$formatted_time:----------(now)\n";
    }
    foreach my $line (@crontab) {

        # コメント行や空行はスキップ
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;

        # 行を分解
        my ($minute, $hour, $day_of_month, $month, $day_of_week, $command) = split /\s+/, $line, 6;
        chomp($command);

        # 実行日時を計算
        my ($sec, $min, $hr, $mday, $mon, $year, $wday) = localtime $current_time;
        $mon++; # 月は 1-12

        # 各フィールドの条件を満たすか確認
        next unless check_field($minute, $min);
        next unless check_field($hour, $hr);
        next unless check_field($day_of_month, $mday);
        next unless check_field($month, $mon);
        next unless check_field($day_of_week, $wday);

        # 実行日時とコマンドを出力
        my $formatted_time = strftime "%Y-%m-%d %a %H:%M", localtime $current_time;
        print "$formatted_time: $command\n";
    }
}

# フィールドの条件を満たすか確認するサブルーチン
sub check_field {
    my ($field, $value) = @_;

    if ($field eq '*') {
        return 1;
    } elsif ($field =~ /^(\d+)-(\d+)$/) {
        return $value >= $1 && $value <= $2;
    } elsif ($field =~ /^(\d+)\/(\d+)$/) {
        return ($value - $1) % $2 == 0;
    } elsif ($field =~ /^(\d+)(?:,(\d+))*$/) {
        foreach my $f (split /,/, $field) { # カンマ区切りの値を処理
            return 1 if $value == $f;
        }
        return 0;
    } else {
        return $value == $field;
    }
}

