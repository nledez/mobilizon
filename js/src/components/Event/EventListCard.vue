<docs>
A simple card for a participation (we should rename it)

```vue
<template>
  <div>
    <EventListCard
      :participation="participation"
      />
  </div>
</template>
<script>
export default {
  data() {
    return {
      participation: {
        event: { 
          title: 'Vue Styleguidist first meetup: learn the basics!',
          id: 5,
          uuid: 'some uuid',
          beginsOn: new Date(),
          organizerActor: {
            preferredUsername: 'tcit',
            name: 'Some Random Dude',
            domain: null,
            id: 4,
            displayName() { return 'Some random dude' }
          },
          options: {
            maximumAttendeeCapacity: 4
          },
          participantStats: {
            approved: 1,
            unapproved: 2
          }
        },
        actor: {
          preferredUsername: 'tcit',
            name: 'Some Random Dude',
            domain: null,
            id: 4,
            displayName() { return 'Some random dude' }
        },
        role: 'CREATOR',
      }
    }
  }
}
</script>
```
</docs>

<template>
  <article class="box">
    <div class="columns">
      <div class="content column">
        <div class="title-wrapper">
          <div class="date-component">
            <date-calendar-icon :date="participation.event.beginsOn" />
          </div>
          <h2 class="title">{{ participation.event.title }}</h2>
        </div>
        <div class="participation-actor has-text-grey">
          <span v-if="participation.event.physicalAddress && participation.event.physicalAddress.locality">{{ participation.event.physicalAddress.locality }} - </span>
          <span>
            <span>{{ $t('Organized by {name}', { name: participation.event.organizerActor.displayName() } ) }}</span>
            <span v-if="participation.role === ParticipantRole.PARTICIPANT">{{ $t('Going as {name}', { name: participation.actor.displayName() }) }}</span>
          </span>
        </div>
        <div class="columns">
          <span class="column is-narrow">
            <b-icon icon="earth" v-if="participation.event.visibility === EventVisibility.PUBLIC" />
            <b-icon icon="lock-open" v-if="participation.event.visibility === EventVisibility.UNLISTED" />
            <b-icon icon="lock" v-if="participation.event.visibility === EventVisibility.PRIVATE" />
          </span>
          <span class="column is-narrow participant-stats">
            <span v-if="participation.event.options.maximumAttendeeCapacity !== 0">
              {{ $t('{approved} / {total} seats', {approved: participation.event.participantStats.participants, total: participation.event.options.maximumAttendeeCapacity }) }}
<!--              <b-progress-->
<!--                      v-if="participation.event.options.maximumAttendeeCapacity > 0"-->
<!--                      size="is-medium"-->
<!--                      :value="participation.event.participantStats.participants * 100 / participation.event.options.maximumAttendeeCapacity">-->
<!--              </b-progress>-->
            </span>
            <span v-else>
              {{ $tc('{count} participants', participation.event.participantStats.participants, { count: participation.event.participantStats.participants })}}
            </span>
            <span
              v-if="participation.event.participantStats.unapproved > 0">
              <b-button type="is-text" @click="gotToWithCheck(participation, { name: RouteName.PARTICIPATIONS, params: { eventId: participation.event.uuid } })">
                {{ $tc('{count} requests waiting', participation.event.participantStats.unapproved, { count: participation.event.participantStats.unapproved })}}
              </b-button>
            </span>
          </span>
        </div>
      </div>
      <div class="actions column is-narrow">
        <ul>
          <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
            <b-button
                    type="is-text"
                    @click="gotToWithCheck(participation, { name: RouteName.EDIT_EVENT, params: { eventId: participation.event.uuid }  })"
                    icon-left="pencil"
            >
              {{ $t('Edit') }}
            </b-button>
          </li>
          <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))" @click="openDeleteEventModalWrapper">
            <b-button type="is-text" icon-left="delete">
              {{ $t('Delete') }}
            </b-button>
          </li>
          <li v-if="!([ParticipantRole.PARTICIPANT, ParticipantRole.NOT_APPROVED].includes(participation.role))">
            <b-button
                    type="is-text"
                    @click="gotToWithCheck(participation, { name: RouteName.PARTICIPATIONS, params: { eventId: participation.event.uuid } })"
                    icon-left="account-multiple-plus"
            >
              {{ $t('Manage participations') }}
            </b-button>
          </li>
          <li>
            <b-button
              tag="router-link"
              icon-left="view-compact"
              type="is-text"
              :to="{ name: RouteName.EVENT, params: { uuid: participation.event.uuid } }">
              {{ $t('View event page') }}
            </b-button>
          </li>
        </ul>
      </div>
    </div>
    </article>
</template>

<script lang="ts">
import { IParticipant, ParticipantRole, EventVisibility, IEventCardOptions } from '@/types/event.model';
import { Component, Prop } from 'vue-property-decorator';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import { IPerson } from '@/types/actor';
import { mixins } from 'vue-class-component';
import ActorMixin from '@/mixins/actor';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import EventMixin from '@/mixins/event';
import { RouteName } from '@/router';
import { changeIdentity } from '@/utils/auth';
import { Route } from 'vue-router';

const defaultOptions: IEventCardOptions = {
  hideDate: true,
  loggedPerson: false,
  hideDetails: false,
  organizerActor: null,
};

@Component({
  components: {
    DateCalendarIcon,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EventListCard extends mixins(ActorMixin, EventMixin) {
  /**
   * The participation associated
   */
  @Prop({ required: true }) participation!: IParticipant;
  /**
   * Options are merged with default options
   */
  @Prop({ required: false, default: () => defaultOptions }) options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;
  EventVisibility = EventVisibility;
  RouteName = RouteName;

  get mergedOptions(): IEventCardOptions {
    return { ...defaultOptions, ...this.options };
  }

  /**
   * Delete the event
   */
  async openDeleteEventModalWrapper() {
    await this.openDeleteEventModal(this.participation.event, this.currentActor);
  }

  async gotToWithCheck(participation: IParticipant, route: Route) {
    if (participation.actor.id !== this.currentActor.id && participation.event.organizerActor) {
      const organizer = participation.event.organizerActor as IPerson;
      await changeIdentity(this.$apollo.provider.defaultClient, organizer);
      this.$buefy.notification.open({
        message: this.$t('Current identity has been changed to {identityName} in order to manage this event.', {
          identityName: organizer.preferredUsername,
        }) as string,
        type: 'is-info',
        position: 'is-bottom-right',
        duration: 5000,
      });
    }
    return await this.$router.push(route);
  }

}
</script>

<style lang="scss" scoped>
  @import "../../variables";

  article.box {
    div.tag-container {
      position: absolute;
      top: 10px;
      right: 0;
      margin-right: -5px;
      z-index: 10;
      max-width: 40%;

      span.tag {
        margin: 5px auto;
        box-shadow: 0 0 5px 0 rgba(0, 0, 0, 1);
        /*word-break: break-all;*/
        text-overflow: ellipsis;
        overflow: hidden;
        display: block;
        /*text-align: right;*/
        font-size: 1em;
        /*padding: 0 1px;*/
        line-height: 1.75em;
      }
    }
    div.content {
      padding: 5px;

      .participation-actor span, .participant-stats span {
        padding: 0 5px;

        button {
          height: auto;
          padding-top: 0;
        }
      }

      div.title-wrapper {
        display: flex;
        align-items: center;

        div.date-component {
          flex: 0;
          margin-right: 16px;
        }

        .title {
          display: -webkit-box;
          -webkit-line-clamp: 1;
          -webkit-box-orient: vertical;
          overflow: hidden;
          font-weight: 400;
          line-height: 1em;
          font-size: 1.6em;
          padding-bottom: 5px;
          margin: auto 0;
        }
      }

      /deep/ progress + .progress-value {
        color: lighten($primary, 20%) !important;
      }
    }

    .actions {
      ul li {
        margin: 0 auto;
        .is-link {
          cursor: pointer;
        }

        .button.is-text {
          text-decoration: none;

          /deep/ span:first-child i.mdi::before {
            font-size: 24px !important;
          }

          /deep/ span:last-child {
            padding-left: 4px;
          }
        }

        * {
          font-size: 0.8rem;
          color: $primary;
        }
      }
    }
  }

</style>
