import { i18n } from '@/utils/i18n';

export const refreshSuggestion = i18n.t('Please refresh the page and retry.') as string;

export const defaultError: IError = {
  match: / /,
  value: i18n.t('An error has occurred.') as string,
};

export interface IError { match: RegExp; value: string; suggestRefresh?: boolean; }

export const errors: IError[] = [
  {
    match: /^Event with UUID .* not found$/,
    value: i18n.t('Page not found') as string,
    suggestRefresh: false,
  },
  {
    match: /^Event not found$/,
    value: i18n.t('Event not found.') as string,
  },
  {
    match: /^Event with this ID .* doesn't exist$/,
    value: i18n.t('Event not found.') as string,
  },
  {
    match: /^Error while saving report$/,
    value: i18n.t('Error while saving report.') as string,
  },
  {
    match: /^Participant already has role rejected$/,
    value: i18n.t('Participant already was rejected.') as string,
  },
  {
    match: /^Participant already has role participant$/,
    value: i18n.t('Participant has already been approved as participant.') as string,
  },
  {
    match: /^You are already a participant of this event$/,
    value: i18n.t('You are already a participant of this event.') as string,
  },
  {
    match: /NetworkError when attempting to fetch resource.$/,
    value: i18n.t('Error while communicating with the server.') as string,
  },

];
