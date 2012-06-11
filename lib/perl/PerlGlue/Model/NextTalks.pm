use MooseX::Declare;

class PerlGlue::Model::NextTalks extends PerlGlue::Model::Schedule {
  use PerlGlue::DateTime;

  override _retrieveTalksQuery( Int :$offset!, Int :$limit! ) {

    $self->day( new PerlGlue::DateTime );

    my $timeNow         = $self->day->epoch;
    my $inFiveMinsEpoch = $self->day->fiveMinutesFromNow;

    return qq{
      select SQL_CALC_FOUND_ROWS t.*, a.name as author_name
      from talks t
      left join authors a on t.author_id = a.id
      inner join user_schedule sch on sch.talk_id = t.id
      where t.day = ? and t.date between($timeNow AND $inFiveMinsEpoc)
      order by t.date
      limit $offset, $limit
    };
  }
}
