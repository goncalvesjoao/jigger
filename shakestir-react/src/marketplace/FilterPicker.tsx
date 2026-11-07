import { useState } from 'react'
import type { Option } from '../api'
import type { MatchMode } from './filters'

interface Props {
  label: string; options: Option[]; selected: string[]; mode: MatchMode
  loading: boolean; error: boolean; retry: () => void
  onChange: (selected: string[], mode: MatchMode) => void
}
export function FilterPicker({ label, options, selected, mode, loading, error, retry, onChange }: Props) {
  const [search, setSearch] = useState('')
  const matches = options.filter(option => option.name.toLocaleLowerCase().includes(search.trim().toLocaleLowerCase()))
  return <details className="filter-picker">
    <summary>{label} · {selected.length ? `${selected.length} ${mode === 'only' ? 'available · Only these' : 'selected'}` : `Add ${label.toLowerCase()}`}</summary>
    <fieldset>
      <legend>{label}</legend>
      <label>Find {label.toLowerCase()}<input type="search" value={search} onChange={event => setSearch(event.target.value)} /></label>
      <fieldset><legend>Match recipes</legend>
        <label><input type="radio" name={`${label}-mode`} checked={mode === 'include'} onChange={() => onChange(selected, 'include')} />Include these items</label>
        <p>Recipes must contain your selections; other items are allowed.</p>
        <label><input type="radio" name={`${label}-mode`} checked={mode === 'only'} onChange={() => onChange(selected, 'only')} />Use only what I have</label>
        <p>Recipes must use only your selected {label.toLowerCase()}.</p>
      </fieldset>
      {mode === 'only' && <p>Select all {label.toLowerCase()} you have{label === 'Ingredients' ? ', including ice' : ''}. Until you select one, this filter allows all {label.toLowerCase()}.</p>}
      <button type="button" disabled={!selected.length} onClick={() => onChange([], mode)}>Clear selected {label.toLowerCase()}</button>
      {loading && <p role="status">Loading {label.toLowerCase()}…</p>}
      {error && <p role="alert">Could not load {label.toLowerCase()}. <button type="button" onClick={retry}>Retry</button></p>}
      <div className="filter-options">{matches.map(option => <label key={option.id}>
        <input type="checkbox" checked={selected.includes(String(option.id))} onChange={event => onChange(event.target.checked ? [...selected, String(option.id)] : selected.filter(id => id !== String(option.id)), mode)} />{option.name}
      </label>)}</div>
      {!loading && !error && !matches.length && <p>No matching {label.toLowerCase()}. Try another name.</p>}
    </fieldset>
  </details>
}
