use MooseX::Declare;

class PerlGlue::Model::MySchedule extends PerlGlue::Model::Schedule {

  has userId => ( is => 'rw', isa => 'Int' );

  override _retrieveTalksQuery( Int :$offset!, Int :$limit! ) {
    my $userId = $self->userId;
    return qq{ 
      select SQL_CALC_FOUND_ROWS t.*, a.name as author_name
      from talks t
      left join authors a on t.author_id = a.id
      inner join user_schedule sch on sch.talk_id = t.id and sch.user_id = $userId
      where t.day = ? 
      order by t.date 
      limit $offset, $limit
    };
  }
}
